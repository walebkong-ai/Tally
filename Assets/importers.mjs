// Pure share parsing and import review helpers. No DOM, storage, network or authentication.
import * as gameScoring from "./game-scoring.mjs?v=2";

export function parseShareText(text) {
  const cleaned = String(text || "").trim();
  if (!cleaned) return { parsed: null, error: "Paste a share result first." };
  if (cleaned.length > 12000) return { parsed: null, error: "That text is too long. Paste just one game's shared result." };

  const lines = normalizeShareLines(cleaned);
  const identify = (attempt, gameId) => attempt.error ? { ...attempt, gameId } : attempt;
  const attempts = [
    identify(parseWordleShare(lines), 'wordle'),
    identify(parseConnectionsShare(lines), /Connections\s*:?\s*Sports Edition/i.test(cleaned) ? 'connections-sports' : 'connections'),
    identify(parseStrandsShare(lines), 'strands'),
    identify(parseMiniCrosswordShare(lines), 'mini-crossword'),
    identify(parseSpellingBeeShare(lines), 'spelling-bee'),
    identify(parseKrillionShare(lines), 'krillion'),
    parseAdditionalShare(lines),
    parseVerifiedShare(lines)
  ];
  if (attempts.filter((attempt) => attempt.parsed || attempt.error).length > 1) {
    return { parsed: null, error: "There is more than one game here. Paste one result at a time so each score goes to the right scoreboard." };
  }
  const parsedAttempt = attempts.find((attempt) => attempt.parsed);
  if (parsedAttempt) {
    if (parsedAttempt.parsed.grid?.length > 100) return { parsed: null, gameId: parsedAttempt.parsed.gameId, error: "This recap has more than 100 rows. Use manual entry so it can sync safely; your paste is kept here." };
    return enrichResult(parsedAttempt, cleaned);
  }

  const knownError = attempts.find((attempt) => attempt.error);
  return knownError || {
    parsed: null,
    error: "I could not identify this result. Copy the full result including its game name or link. Check Supported games & sample results, or use Enter manually for another game."
  };
}

function parseAdditionalShare(lines) {
  const text = lines.join("\n");
  const games = [
    ["daily-tens", /\bDaily\s*Tens\b/i], ["centumth", /\bCentumth\b/i],
    ["globle", /(?:#globle\b|globle-game\.com|^Globle\b)/im],
    ["flagcognito", /\bFlagcognito\b/i], ["size-it-up", /\bSize It Up\b|magnitudle\.com\/size-it-up/i],
    ["color", /dialed\.gg\/color(?:[?\s/#]|$)/i],
    ["buzzfeed-trivia", /buzzfeed\.com\/daily-trivia|BuzzFeed.*Daily Trivia/i],
    ["immaculate", /\bImmaculate Grid\b/i]
  ].filter(([, pattern]) => pattern.test(text));
  const fail = (error) => ({ parsed: null, error, gameId: games.length === 1 ? games[0][0] : undefined });
  if (!games.length) return { parsed: null };
  if (games.length > 1) return fail("Paste one result at a time so each game reaches the right scoreboard.");
  const id = games[0][0];
  const finish = (gameId, score, result = "played", grid = []) => ({ parsed: { gameId, score, result, grid, note: "Imported shared result" } });
  const total = (pattern, max, decimal = false) => {
    const matches = [...text.matchAll(pattern)];
    if (matches.length !== 1) return null;
    const raw = matches[0][1].replace(/,/g, "");
    const denominator = matches[0][2].replace(/,/g, "");
    const number = Number(raw);
    return (decimal ? /^\d+(?:\.\d{1,2})?$/.test(raw) : /^\d+$/.test(raw)) && Number(denominator) === max && number >= 0 && number <= max ? number : null;
  };
  if (id === "daily-tens") {
    const grid = lines.map(compactEmojiLine).filter((line) => /[🏆❌]/u.test(line));
    if (grid.length !== 5 || grid.some((line) => !/^[🏆❌]{2}$/u.test(line))) return fail("Daily Tens needs all five rows of two trophies/crosses. Copy the full result from Share.");
    const correct = (grid.join("").match(/🏆/gu) || []).length;
    return finish(id, `${correct}/10`, correct === 10 ? "solved" : "played", grid);
  }
  if (id === "centumth") {
    const score = total(/^Total:\s*([\d,]+)\s*\/\s*(\d+)(?![\d.])/gim, 490);
    return score === null ? fail("Copy Centumth’s final Total: …/490 line. Individual guesses and Arcade scores aren't the daily total.") : finish(id, `${score}/490`);
  }
  if (id === "globle") {
    if (/capitals/i.test(text)) return fail("This is Globle Capitals. Use a separate Other game entry; Globle tracks the country game.");
    const results = lines.filter((line) => /=/.test(line));
    const match = results.length === 1 && results[0].match(/^[\s🟥🟧🟨🟩🟦🟪⬜⬛]+\s*=\s*([1-9]\d*)$/u);
    if (!match || Number(match[1]) > 1000000) return fail("Copy Globle’s completed emoji result with = followed by today's guess count. A streak or average isn't a daily score.");
    return finish(id, `${Number(match[1])} guess${Number(match[1]) === 1 ? "" : "es"}`, "solved", results);
  }
  if (id === "flagcognito") {
    const score = total(/^\s*([\d,]+)\s*\/\s*([\d,]+)\s*$/gm, 3000);
    return score === null ? fail("Copy Flagcognito’s final total out of 3,000, including the game name. Tap counts and distances aren't the score.") : finish(id, `${score}/3000`);
  }
  if (id === "size-it-up") {
    if (/\b(practice|unlimited|pop culture|weekly|geography)\b/i.test(text)) return fail("This scoreboard is for original daily Size It Up. Track other editions or practice with a separate Other game entry.");
    if (!/magnitudle/i.test(text)) return fail("Include the Magnitudle name or official Size It Up link so we can identify the edition.");
    const score = total(/^Score:\s*([\d,]+)\s*\/\s*(\d+)\s*$/gim, 500);
    return score === null ? fail("Copy Size It Up’s final Score: …/500 line, not an individual round.") : finish(id, `${score}/500`);
  }
  if (id === "color") {
    if (/dialed\.gg\/color\/(?:live|toon)|\blive game\b/i.test(text)) return fail("Use the Color memory result, not a live room or another Dialed game.");
    const score = total(/(?<![\w.\-])(\d+(?:\.\d+)?)\s*\/\s*(50)(?!\d|\.\d)/g, 50, true);
    if (score === null) return fail("This Color link doesn't include a readable score. Copy the result text with your score out of 50, or enter it manually.");
    const output = finish(id, `${score}/50`);
    if (/^Color Daily\b/im.test(text)) {
      const daily = text.match(/^Color Daily\s*[—–-]\s*([A-Za-z]+)\s+(\d{1,2})(?:,?\s+(\d{4}))?\s*$/im);
      const months = ["jan", "feb", "mar", "apr", "may", "jun", "jul", "aug", "sep", "oct", "nov", "dec"];
      const month = daily ? months.indexOf(daily[1].slice(0, 3).toLowerCase()) + 1 : 0;
      const day = daily ? Number(daily[2]) : 0;
      const validDay = new Date(Date.UTC(Number(daily?.[3] || 2024), month - 1, day)).getUTCDate() === day;
      if (!daily || !month || !day || !validDay || !/https?:\/\/(?:www\.)?dialed\.gg\/color\?[^\s]*\bd=1(?:&|$|\s)/im.test(text)) return fail("Copy the complete Color Daily result including its date and daily link.");
      output.parsed.dailyMonthDay = `${String(month).padStart(2, "0")}-${String(day).padStart(2, "0")}`;
      output.parsed.dailyYear = daily[3] || null;
      output.parsed.note = "Imported Color Daily result";
    }
    return output;
  }
  if (id === "buzzfeed-trivia") {
    const score = total(/\bI got\s+(\d+)\s+out of\s+(\d+)\b/gi, 5);
    return score === null ? fail("Copy BuzzFeed Daily Trivia’s full result: I got … out of 5, plus the Daily Trivia link.") : finish(id, `${score}/5`, score === 5 ? "solved" : "played");
  }
  const headers = lines.filter((line) => /Immaculate Grid/i.test(line));
  if (headers.length !== 1) return fail("Paste one Immaculate Grid result, with its sport and rarity score.");
  const sportMatches = [
    ["baseball", /⚾|\bbaseball\b/i], ["football", /🏈|\bfootball\b/i],
    ["basketball-women", /\bwomen[’']?s\b|\/basketball\/womens\//i],
    ["hockey", /🏒|\bhockey\b/i]
  ].filter(([, pattern]) => pattern.test(text));
  if (/🏀|\bbasketball\b|\bmen[’']?s\b/i.test(text) && !sportMatches.some(([sport]) => sport === "basketball-women")) sportMatches.push(["basketball-men"]);
  if (sportMatches.length !== 1) return fail("Include the sport emoji or name in your Immaculate Grid result so it goes to the correct sport's scoreboard.");
  const count = headers[0].match(/\b([0-9])\s*\/\s*9\b/);
  const rarities = lines.filter((line) => /^Rarity(?: score)?:/i.test(line));
  const rarity = rarities.length === 1 && rarities[0].match(/^Rarity(?: score)?:\s*(\d+(?:\.\d+)?)\s*$/i);
  if (!count || !rarity || Number(rarity[1]) > 900) return fail("Include correct answers out of 9 and Rarity: followed by its score (0–900). Rarity is not a percentage.");
  const grid = lines.map(compactEmojiLine).filter((line) => /[🟩⬜⬛]/u.test(line));
  if (grid.length && (grid.length !== 3 || grid.some((line) => !/^[🟩⬜⬛]{3}$/u.test(line)) || (grid.join("").match(/🟩/gu) || []).length !== Number(count[1]))) return fail("The Immaculate Grid squares don't match the score. Copy the complete 3×3 result again.");
  return finish(`immaculate-${sportMatches[0][0]}`, `${Number(count[1])}/9 · rarity ${Number(rarity[1])}`, count[1] === "9" ? "solved" : "played", grid);
}

function parseWordleShare(lines) {
  const headers = lines.filter((line) => /^Wordle\b/i.test(line));
  if (!headers.length) return { parsed: null };
  if (headers.length !== 1) return { parsed: null, error: "Paste one Wordle result at a time." };
  const scoreMatch = headers[0].match(/^Wordle(?:\s+#?([\d,]+))?\s+([1-6X])\/6\*?$/i);
  if (!scoreMatch) {
    return {
      parsed: null,
      error: "I found Wordle, but I could not find a score like 4/6 or X/6. Paste the result line plus the emoji grid."
    };
  }

  const grid = lines.map(compactEmojiLine).filter((line) => /[🟩🟨⬛⬜🟦🟧🟥🟪]/u.test(line));
  const rawScore = scoreMatch[2].toUpperCase();
  const score = `${rawScore}/6`;
  const solvedRow = (row) => /^(?:🟩{5}|🟧{5})$/u.test(row);
  if (grid.length && (grid.some((row) => !/^[🟩🟨⬛⬜🟦🟧]{5}$/u.test(row))
    || grid.length !== (rawScore === "X" ? 6 : Number(rawScore))
    || (rawScore === "X" ? grid.some(solvedRow) : !solvedRow(grid.at(-1)) || grid.slice(0, -1).some(solvedRow)))) {
    return { parsed: null, error: "The Wordle grid does not match its score. Copy one complete result with five squares per row." };
  }

  return {
    parsed: {
      gameId: "wordle",
      score,
      result: rawScore === "X" ? "missed" : "solved",
      note: `Imported official Wordle${scoreMatch[1] ? ` #${scoreMatch[1]}` : ""}${grid.length ? ` with ${grid.length} rows` : ""}`,
      grid
    }
  };
}

function parseConnectionsShare(lines) {
  const text = lines.join(" ");
  const header = lines.find((line) => /^Connections\b/i.test(line)) || (/\bConnections\b/i.test(text) ? text : "");
  if (!header) return { parsed: null };

  const sports = /Connections\s*:?\s*Sports Edition/i.test(header);
  const headers = lines.filter((line) => /^Connections\b/i.test(line));
  if (headers.length > 1) return { parsed: null, error: "Paste one Connections result at a time, including its edition." };
  const gridPattern = /^[\u{1F7E8}\u{1F7E9}\u{1F7E6}\u{1F7EA}]{4}$/u;
  const grid = lines
    .map((line) => sports ? line.replace(/🟡/gu, "🟨").replace(/🟢/gu, "🟩").replace(/🔵/gu, "🟦").replace(/🟣/gu, "🟪") : line)
    .map(compactEmojiLine)
    .filter((line) => /[🟨🟩🟦🟪🟥🟧⬜⬛🟡🟢🔵🟣]/u.test(line));
  if (grid.some((line) => !gridPattern.test(line))) return { parsed: null, error: "A Connections row is incomplete or invalid. Copy every row with exactly four colored squares." };
  if (!grid.length) {
    return {
      parsed: null,
      error: "I found Connections, but I could not find the four-color emoji grid. Paste the full shared result, including the colored square rows."
    };
  }

  const puzzleMatch = text.match(/(?:Puzzle\s*)?#\s*([\d,]+)/i) || text.match(/\bConnections\s+#?([\d,]+)/i);
  const correctRows = grid.filter((line) => /^([\u{1F7E8}]{4}|[\u{1F7E9}]{4}|[\u{1F7E6}]{4}|[\u{1F7EA}]{4})$/u.test(line));
  const solvedRows = new Set(correctRows).size;
  const mistakes = grid.length - correctRows.length;
  if (grid.length > 7 || mistakes > 4 || solvedRows !== correctRows.length) return { parsed: null, error: "This Connections grid has repeated groups or too many rows. Paste one complete result." };
  let groups = 0, errors = 0;
  for (let index = 0; index < grid.length; index++) {
    if (correctRows.includes(grid[index])) groups++; else errors++;
    if (index < grid.length - 1 && (groups === 4 || errors === 4)) return { parsed: null, error: "This Connections grid continues after the game ended. Paste one result." };
  }

  return {
    parsed: {
      gameId: sports ? "connections-sports" : "connections",
      score: `${mistakes} mistake${mistakes === 1 ? "" : "s"}`,
      result: solvedRows >= 4 ? "solved" : mistakes >= 4 ? "missed" : "played",
      note: `Imported official Connections${puzzleMatch ? ` #${puzzleMatch[1]}` : ""} with ${grid.length} rows`,
      grid
    }
  };
}

function parseStrandsShare(lines) {
  const text = lines.join(" ");
  const header = lines.find((line) => /^Strands\b/i.test(line)) || (/\bStrands\b/i.test(text) ? text : "");
  if (!header) return { parsed: null };
  if (lines.filter(line => /^Strands\b/i.test(line)).length > 1) return { parsed: null, error: "Paste one Strands result at a time." };
  const grid = lines
    .map(compactEmojiLine)
    .filter((line) => /[🔵🟡💡]/u.test(line));
  if (grid.some(line => !/^[🔵🟡💡]+$/u.test(line)) || (grid.join("").match(/🟡/gu) || []).length > 1) return { parsed: null, error: "The Strands recap is malformed. Copy one full result." };
  if (!grid.length) {
    return {
      parsed: null,
      error: "I found Strands, but I could not find the blue/yellow/hint emoji recap. Paste the full shared result."
    };
  }

  const puzzleMatch = text.match(/#\s*([\d,]+)/i) || text.match(/\bStrands\s+#?([\d,]+)/i);
  const hintCount = (grid.join("").match(/\u{1F4A1}/gu) || []).length;
  const foundSpangram = grid.some((line) => /\u{1F7E1}/u.test(line));
  const score = hintCount ? `${hintCount} hint${hintCount === 1 ? "" : "s"}` : "No hints";

  return {
    parsed: {
      gameId: "strands",
      score,
      result: "played",
      completionUnverified: true,
      note: `Imported official Strands${puzzleMatch ? ` #${puzzleMatch[1]}` : ""}${foundSpangram ? " with spangram" : ""}; completion unverified`,
      grid
    }
  };
}

function parseMiniCrosswordShare(lines) {
  const text = lines.join(" ");
  if (!/\b(Mini Crossword|The Mini|NYT Mini|New York Times Mini)\b/i.test(text)) return { parsed: null };

  const times = [...text.matchAll(/(?<![\w.:])[-+]?\d+(?::\d+)+(?:\.\d+)?(?![\w.:])/g)];
  if (times.length > 1 || times.length === 1 && !/^\d{1,2}:\d{2}(?::\d{2})?$/.test(times[0][0])) {
    return { parsed: null, error: "Copy one positive completion time, without competing times or partial numbers." };
  }
  const timeMatch = times.length === 1 ? [times[0][0], times[0][0]] : null;
  if (!timeMatch) {
    return {
      parsed: null,
      error: "I found Mini Crossword, but I could not find a completion time like 0:54 or 12:03."
    };
  }
  if (timeMatch[1].split(":").slice(1).some((part) => Number(part) > 59)) {
    return { parsed: null, error: "That time doesn't look right. Seconds and minutes within an hour must be between 00 and 59." };
  }
  if (!Number.isFinite(gameScoring.timeSeconds(timeMatch[1]))) return { parsed: null, error: "Enter a completion time greater than 00:00." };

  return {
    parsed: {
      gameId: "mini-crossword",
      score: normalizeTimeScore(timeMatch[1]),
      result: "solved",
      note: "Imported official Mini Crossword time",
      grid: []
    }
  };
}

function parseSpellingBeeShare(lines) {
  const text = lines.join(" ");
  if (!/Spelling Bee/i.test(text)) return { parsed: null };

  const ranks = ["Queen Bee", "Genius", "Amazing", "Great", "Nice", "Solid", "Good Start", "Good", "Moving Up", "Moving", "Beginner"];
  const matches = [...text.matchAll(new RegExp(`\\b(${ranks.join('|')})\\b`, 'gi'))];
  const distinct = new Set(matches.map(match => match[1].toLowerCase()));
  if (distinct.size > 1) return { parsed: null, error: "This Spelling Bee paste contains competing ranks. Copy one result." };
  const rank = ranks.find(item => item.toLowerCase() === matches[0]?.[1].toLowerCase());
  if (!rank) {
    return {
      parsed: null,
      error: "I found Spelling Bee, but I could not find a rank like Genius, Amazing, or Queen Bee."
    };
  }

  const pointMatch = text.match(/\b(\d{1,4})\s*(?:points?|pts?)\b/i);
  const score = pointMatch ? `${rank} · ${pointMatch[1]} pts` : rank;

  return {
    parsed: {
      gameId: "spelling-bee",
      score,
      result: rank === "Queen Bee" ? "solved" : "played",
      note: `Imported official Spelling Bee rank: ${rank}`,
      grid: []
    }
  };
}

function parseKrillionShare(lines) {
  const text = lines.join(" ");
  const header = lines.find((line) => /^Krillion\b/i.test(line)) || (/\bKrillion\b/i.test(text) ? text : "");
  if (!header) return { parsed: null };

  const headerIndex = lines.indexOf(header);
  const searchableLines = headerIndex >= 0 ? lines.slice(headerIndex + 1) : lines;
  const directScores = searchableLines.filter(line => /^[-+]?[\d,]+(?:\.\d+)?$/.test(line));
  const labeledScores = [...text.matchAll(/\b(?:score|depth|total)\s*:?\s*([-+]?[\d,]+(?:\.\d+)?)(?![\d.])/gi)];
  const pointScores = [...text.matchAll(/(?<![\w.,-])([-+]?[\d,]+(?:\.\d+)?)\s*(?:depth\s*)?(?:points?|pts?)\b/gi)];
  const candidates = [...directScores, ...labeledScores.map(match=>match[1]), ...pointScores.map(match=>match[1])];
  if (new Set(candidates).size > 1 || candidates.some(score=>!/^\d{1,4}$/.test(score))) return { parsed: null, error: "Copy one whole-number Krillion total from 0 to 9999, without competing scores." };
  const scoreLine = candidates[0];
  if (!scoreLine) {
    return {
      parsed: null,
      error: "I found Krillion, but I could not find the total depth score. Paste the line with the final number, like 110."
    };
  }

  const numberMatch = text.match(/\bKrillion\s+#?([\d,]+)/i);
  const grid = lines
    .slice(Math.max(lines.indexOf(String(scoreLine)) + 1, 0))
    .filter((line) => !/^https?:\/\//i.test(line) && line !== scoreLine && !/^Krillion\b/i.test(line));

  return {
    parsed: {
      gameId: "krillion",
      score: scoreLine,
      result: Number(scoreLine) > 0 ? "played" : "missed",
      note: `Imported official Krillion #${numberMatch?.[1] || "daily dive"} with ${scoreLine} depth points`,
      grid
    }
  };
}

function normalizeShareLines(text) {
  return text
    .replace(/\uFE0F/g, "")
    .split(/\r?\n/)
    .map((line) => line.trim())
    .filter(Boolean);
}

function compactEmojiLine(line) {
  return line.replace(/[\s\u200B-\u200D]/g, "");
}

function normalizeTimeScore(score) {
  const parts = score.split(":");
  return parts.length === 2 ? score.padStart(5, "0") : score;
}

export const SUPPORTED_GAME_IDS = Object.freeze([
  'wordle','connections','strands','mini-crossword','spelling-bee','krillion',
  'connections-sports','daily-tens','centumth','globle','flagcognito','size-it-up','color','buzzfeed-trivia',
  'contexto','costcodle','squirdle','poople','chainle'
]);
export const MAX_RESULTS = 10;
const failure = (error, gameId) => ({parsed:null,error,gameId});

export function validDate(value) {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(value || '') || value.slice(0,4) < '1000') return false;
  const [year,month,day] = value.split('-').map(Number);
  const date = new Date(Date.UTC(year,month-1,day));
  return date.getUTCFullYear()===year && date.getUTCMonth()===month-1 && date.getUTCDate()===day;
}

function parseVerifiedShare(lines) {
  const text=lines.join('\n'), finish=(gameId,score,result,puzzleId,grid,extra={})=>({parsed:{gameId,score,result,puzzleId,grid,note:'Imported daily shared result',...extra}});
  if (/contexto\.me/i.test(text)) {
    const match=lines[0]?.match(/^I played contexto\.me (\d{2})\/(\d{2})\/(\d{4}) (and got it|but I gave up) in (\d+) guesses(?: and (\d+) hints)?\.$/i);
    if (!match) return failure('Copy the complete English daily Contexto share. Unlimited and other languages need manual entry.','contexto');
    const date=`${match[3]}-${match[1]}-${match[2]}`, n=Number(match[5]), missed=/gave up/i.test(match[4]);
    const chart=lines.slice(1), colors=['🟩','🟨','🟥'];
    if (!validDate(date) || n>1000000 || (!missed && n<1) || chart.length!==3 || chart.some((line,i)=>{
      const row=line.match(new RegExp(`^(${colors[i]}*)\\s*(\\d+)$`,'u'));
      return !row || Number(row[2])>1000000 || [...row[1]].length>Number(row[2]) || (!!row[1] !== (Number(row[2])>0));
    })) return failure('The Contexto date or guess recap is incomplete. Copy one full result.','contexto');
    if (!Number(match[6]||0) && chart.reduce((sum,line)=>sum+Number(line.match(/\d+$/)[0]),0)!==n) return failure('The Contexto recap counts do not match its guess count. Copy one complete result.','contexto');
    if (Number(match[6]||0)>0 && !missed) return failure('This Contexto solve used hints. This board compares unassisted solves; use manual entry to record an unranked Played result.','contexto');
    return finish('contexto',`${n} guess${n===1?'':'es'}`,missed?'missed':'solved',date,lines.slice(1),{date,dateSource:'Printed daily date',guesses:n});
  }
  if (/\bCostcodle\b/i.test(text)) {
    const m=lines[0]?.match(/^Costcodle Classic #(\d+) ([1-6X])\/6$/i);
    if (!m || Number(m[1])<1 || Number(m[1])>1000000) return failure('Copy Costcodle Classic’s daily #number and score out of 6. Checkout is a different game.','costcodle');
    const grid=lines.slice(1).filter(line=>!/^Play now at https:\/\/(?:www\.)?costcodle\.com\/?$/i.test(line));
    const missed=m[2].toUpperCase()==='X', count=missed?6:Number(m[2]);
    if (grid.some(line=>!/^(?:[⬆⬇][🟥🟨]|✅)$/u.test(line)) || grid.length && (grid.length!==count || grid.slice(0,-1).includes('✅') || (missed?grid.includes('✅'):grid.at(-1)!=='✅'))) return failure('The Costcodle arrows do not match its final score. Copy one complete Classic result.','costcodle');
    // Publisher main.js: COSTCODLE_EPOCH_UTC + (gameNumber - 2) * 86400000.
    const date=new Date(Date.UTC(2023,8,21)+(Number(m[1])-2)*86400000).toISOString().slice(0,10);
    return finish('costcodle',missed?'Missed':`${count} guess${count===1?'':'es'}`,missed?'missed':'solved',String(Number(m[1])),grid,{date,dateSource:'Publisher’s Classic puzzle calendar'});
  }
  if (/\bSquirdle\b/i.test(text)) {
    const m=lines[0]?.match(/^Squirdle Daily (\d+) - ([1-9X])\/9$/i);
    if (!m || Number(m[1])>1000000) return failure('Copy Squirdle Daily’s normal 9-guess share. Free Play, Stats Edition and restricted-generation games need manual entry.','squirdle');
    const rows=lines.slice(1).map(line=>line.match(/^([✅🔼🔽🟨❌🟦]{5})([\p{L}\p{N}\s.:'’♀♂-]*)$/u));
    const missed=m[2].toUpperCase()==='X', count=missed?9:Number(m[2]);
    if (rows.some(row=>!row) || rows.length!==count || rows.slice(0,-1).some(row=>row[1]==='✅✅✅✅✅') || (missed?rows.some(row=>row[1]==='✅✅✅✅✅'):rows.at(-1)?.[1]!=='✅✅✅✅✅')) return failure('The Squirdle daily mosaic does not match its score. Include all five-column rows.','squirdle');
    return finish('squirdle',missed?'Missed':`${count} guess${count===1?'':'es'}`,missed?'missed':'solved',String(Number(m[1])),lines.slice(1));
  }
  if (/\bPoople\b|poople\.io/i.test(text)) {
    const m=lines[0]?.match(/^Poople #(\d+) (\d+)\/(\d+)$/i);
    if (!m || Number(m[1])>1000000 || Number(m[2])<1 || Number(m[2])>1000000 || Number(m[3])<1 || Number(m[3])>Number(m[2])) return failure('Copy Poople’s complete daily share. The second number is the best solution, not an attempt limit.','poople');
    const grid=lines.slice(1).filter(line=>!/^https:\/\/poople\.io\/?$/i.test(line));
    const moves=Number(m[2]);
    if (grid.length!==moves+1 || grid.some(row=>!/^[🟫⬜]{4}$/u.test(row)) || grid.at(-1)!=='🟫🟫🟫🟫' || grid.slice(0,-1).includes('🟫🟫🟫🟫')) return failure('Poople needs the starting row and every move, ending in four brown squares.','poople');
    return finish('poople',`${moves} move${moves===1?'':'s'}`,'solved',String(Number(m[1])),grid,{optimalMoves:Number(m[3])});
  }
  if (/\bChainle\b|chainle\.io/i.test(text)) {
    const m=lines[0]?.match(/^Chainle #(\d+) · (\d{1,3}(?:,\d{3})*|\d+) 🔗$/i);
    if (!m || Number(m[1])>1000000) return failure('Copy Chainle’s daily #number, total points and five-round recap. Unlimited needs manual entry.','chainle');
    const rest=lines.slice(1).filter(line=>!/^https:\/\/chainle\.io\/?$/i.test(line) && !/^Beat (?:100|\d{1,2})(?:\.\d+)?% of players$/.test(line));
    const grid=rest[0], points=Number(m[2].replaceAll(',','')), bands={'🟩':[900,1000],'🟨':[600,899],'🟧':[300,599],'🟥':[0,299]};
    if (rest.length!==1 || !/^[🟩🟨🟧🟥]{5}$/u.test(grid)) return failure('Chainle needs all five round colors. Copy the finished daily result.','chainle');
    const limits=[...grid].reduce((sum,color)=>sum.map((n,i)=>n+bands[color][i]),[0,0]);
    if (points<limits[0] || points>limits[1]) return failure('The Chainle total does not match the five round colors. Copy the full result again.','chainle');
    return finish('chainle',String(points),'played',String(Number(m[1])),[grid]);
  }
  return {parsed:null};
}

function enrichResult(attempt, text) {
  const p=attempt.parsed;
  const patterns={wordle:/^Wordle\s+#?([\d,]+)\s+[1-6X]\/6/im,connections:/(?:\bPuzzle\s*#\s*|^Connections\s+#?)([\d,]+)/im,'connections-sports':/(?:\bPuzzle\s*#\s*|^Connections\s*:?\s*Sports Edition\s+#?)([\d,]+)/im,strands:/^Strands\s*#\s*([\d,]+)/im,krillion:/^Krillion\s*#\s*([\d,]+)/im,'daily-tens':/^Daily\s*Tens\s*#\s*([\d,]+)/im};
  const id=patterns[p.gameId]?.exec(text)?.[1];
  if (id) p.puzzleId=id.replaceAll(',','');
  if (['globle','centumth','flagcognito','size-it-up','color'].includes(p.gameId)) {
    const dateText=text.split(/\r?\n/).filter(line=>({globle:/^🌎.*🌍\s*$/,centumth:/^Centumth\b/i,flagcognito:/^Flagcognito\b/i,'size-it-up':/^(?:Magnitudle.*Size It Up|[A-Za-z]+ \d{1,2},? \d{4}\s*$)/i,color:/^Color Daily\s*[—–-]/i})[p.gameId].test(line.trim())).join('\n');
    const dates=[...dateText.matchAll(/\b(Jan(?:uary)?|Feb(?:ruary)?|Mar(?:ch)?|Apr(?:il)?|May|Jun(?:e)?|Jul(?:y)?|Aug(?:ust)?|Sep(?:tember)?|Oct(?:ober)?|Nov(?:ember)?|Dec(?:ember)?)\s+(\d{1,2}),?\s+(\d{4})\b/gi)].map(m=>`${m[3]}-${String(['jan','feb','mar','apr','may','jun','jul','aug','sep','oct','nov','dec'].indexOf(m[1].slice(0,3).toLowerCase())+1).padStart(2,'0')}-${m[2].padStart(2,'0')}`);
    if (dates.some(d=>!validDate(d)) || new Set(dates).size>1) return failure('The share contains an invalid or conflicting date. Copy one complete result.',p.gameId);
    if (dates[0]) { p.date=dates[0]; p.dateSource='Printed daily date'; p.puzzleId ||= p.date; }
  }
  return attempt;
}

export function dateError(parsed, date, today) {
  if (!validDate(date)) return 'Choose a valid day you played.';
  if (today && date>today) return 'Future results cannot be saved. Check the played-on date.';
  if (parsed.date && parsed.date!==date) return `This result is dated ${parsed.date}. Change Played on to that date before saving.`;
  if (parsed.dailyMonthDay && (date.slice(5)!==parsed.dailyMonthDay || parsed.dailyYear && date.slice(0,4)!==parsed.dailyYear)) return `This Color Daily result is dated ${parsed.dailyYear?parsed.dailyYear+'-':''}${parsed.dailyMonthDay}. Change Played on to the result's date before saving.`;
  return '';
}

export function sameResult(existing, parsed, date) {
  if (existing?.source!=='official-share' || existing.result!==parsed.result) return false;
  const canonical=score=>/^\d+:\d{2}(?::\d{2})?$/.test(score)?String(gameScoring.timeSeconds(score)):String(score||'').trim().replace(/\s+/g,' ').toLowerCase();
  if (canonical(existing.score)!==canonical(parsed.score)) return false;
  const previous=parseShareText(existing.shareText||'').parsed;
  if (previous && previous.gameId!==parsed.gameId) return false;
  if (parsed.gameId==='color' && !!previous?.dailyMonthDay!==!!parsed.dailyMonthDay) return false;
  if (previous?.puzzleId && parsed.puzzleId && previous.puzzleId!==parsed.puzzleId) return false;
  return (!previous?.date || previous.date===date) && (!parsed.date || parsed.date===date);
}

export function existingPuzzleDate(entries, parsed, date) {
  if (!parsed.puzzleId || parsed.gameId==='color'&&!parsed.dailyMonthDay) return '';
  return Object.keys(entries||{}).find(day=>day!==date && (()=>{
    const entry=entries[day]?.[parsed.gameId]?.you;
    const previous=entry?.source==='official-share' && parseShareText(entry.shareText||'').parsed;
    return previous?.gameId===parsed.gameId && previous.puzzleId===parsed.puzzleId;
  })()) || '';
}

const START=/^(?:Wordle\b|Connections\b|Strands\b|(?:I solved the Mini Crossword|Mini Crossword|The Mini(?: Crossword)?|NYT Mini(?: Crossword)?|New York Times Mini(?: Crossword)?)\b|Spelling Bee\b|Krillion\b|Daily\s*Tens\b|Centumth\b|Globle\b|🌎.*🌍|Flagcognito\b|Magnitudle.*Size It Up|Color Daily\b|My color memory\b|I got \d+ out of \d+.*Daily Trivia|I played contexto\.me\b|Costcodle\b|Squirdle\b|Poople\b|Chainle\b)/iu;
export function splitResults(text, catalog=[]) {
  if (String(text||'').length>12000) return [{text:String(text),parsed:null,error:'Paste up to 10 results and 12,000 characters at a time.'}];
  const lines=String(text||'').replace(/\r\n?/g,'\n').split('\n'), blocks=[];let current=[];
  const flush=()=>{const raw=current.join('\n').trim();if(raw)blocks.push(raw);current=[];};
  for (const line of lines) {
    const trimmed=line.trim();
    const named=catalog.some(game=>game.manualOnly&&!game.pasteSupported && trimmed.toLowerCase().startsWith(game.name.toLowerCase()) && /^(?:\s|#|$)/.test(trimmed.slice(game.name.length)));
    if (/^---+$/.test(trimmed)) {flush();continue;}
    if ((START.test(trimmed)||named) && current.some(s=>s.trim())) flush();
    current.push(line);
  }
  flush();
  if (blocks.length>MAX_RESULTS) return [{text:String(text),parsed:null,error:'Review at most 10 results at a time. Your paste has not been saved.'}];
  return blocks.map(raw=>{
    const result=parseShareText(raw);
    if (!result.parsed && !result.gameId) {
      const first=raw.split('\n')[0].trim().toLowerCase();
      const game=catalog.find(game=>!game.retired && first.startsWith(game.name.toLowerCase()) && /^(?:\s|#|$)/.test(first.slice(game.name.length)));
      if (game?.manualOnly && !game.pasteSupported) return {text:raw,...failure(`${game.name} needs manual entry. Your pasted text is kept here so you can check it while entering the result.`,game.id)};
    }
    return {text:raw,...result};
  });
}
