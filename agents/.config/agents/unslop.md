# Unslop — cut AI tells from prose

Apply before writing any prose an agent produces: code comments, commit messages,
PR/issue descriptions, ticket comments, chat replies. Strip AI tells and keep a
human voice.

- Have an opinion; react to facts instead of neutrally listing pros and cons.
- Name the mechanism or a number instead of describing a feeling: not "SQL you can
  read" but "`.toSQL()` returns the exact string sent to the database".
- Plain words only. "use" not "utilize"/"leverage"; "help" not "facilitate";
  "many" not "numerous".
- Active voice. Catch "is/are/was/were + past participle"; name the actor.
- No em dashes. No parentheses as a crutch. End the sentence or use a comma.
- No colon as a mid-sentence connector.
- No rule-of-three forcing, no false ranges ("from X to Y"), no "It's not just X,
  it's Y" negative parallelism.
- No filler: "In order to" → "To", "Due to the fact that" → "Because". Delete
  "It is important to note that".
- No "I hope this helps!", "Let me know if...", "Great question!" Sycophancy goes.
- One idea per sentence. Split dense sentences.
- Cut adverbs that prop up a weak verb; find the stronger verb or the number.

For the full pattern list, opencode agents should invoke the `unslop` skill.
