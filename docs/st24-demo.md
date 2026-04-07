



Back in 1976 my University had a Univac 1102 or 1103 and we could access it via teletype terminals with paper tape reader/punches.  There was a popular game based on Star Trek that had commands like SRS (Short Range Sensors), LRS (Long Range Sensors), Impulse (move within sector), Warp (move between sectors), Phasers (fire phasers in a direction) [and maybe Torpedoes to launch in a direction].   There may have been more commands and maybe a help command.  When you ran SRS, it printed a grid of nearby stars/planets? and an E for your location, . for empy space, and K for a Klingon ship.  For LRS it showed something like a bigger grid with a count of stars/planets (probably no indication of Klingons).  Both grids have Alphabetic or numeric scales horizontally and vertically.  The LRS might have shown whether it was visited or not.  I do not recall if there was a goal (like find a particular quadrant or star/planet, or destroy all klingons).  When you used WARP to enter a "quadrant" the program would ring the bell multiple times and print something like "*** Klingon Alert ****"  or maybe "*** Red Alert ***" and/or "n Klingon(s) detected".  Any chance that the source for this is available online.  I believe it was written in BASIC.  I think there was a way to save the game state to paper tape (or maybe just save the game source itself).  I recently started a 1970's style BASIC interpreter.  I want to recreate this game as a runnable demo at the command line.  I'd prefer a clean-room clone (from fuzzy memory) that I can release as open source under the MIT License.


Thought

Thought

Thought

Thought
What you want is very plausible: identify the likely historical lineage, separate that from your fuzzy-memory variant, and then design a clean-room 1970s-feeling command-line clone that captures the experience without copying protected source or distinctive prose.

Likely match
Your description lines up very closely with the classic Star Trek / Super Star Trek family of BASIC games that circulated widely on timesharing systems and teletypes in the 1970s. In the widely published Super Star Trek version, the command set includes SRS, LRS, PHA, TOR, SHE, DAM, COM, and NAV; the game uses an 8×8 galaxy of quadrants, each quadrant contains an 8×8 sector grid, and the mission is to destroy all Klingons within a time limit. The published instructions explicitly describe SRS and LRS, and LRS encodes counts as a three-digit value where hundreds = Klingons, tens = starbases, units = stars. 

A few details from your memory differ from the Ahl/Leedom listing, which is normal after 50 years. In the 1975/1976 published Super Star Trek, movement is under NAV rather than separate WARP and IMPULSE commands, the Enterprise is shown as (*) in the help text, Klingons as +++, and starbases as >!<. The command prompt also includes XXX to resign command. 

Why your remembered version may still be real
There were many Star Trek variants by the mid-to-late 1970s, and the game was ported and expanded repeatedly. The overall family started with Mike Mayfield’s 1971 BASIC game, was ported by David Ahl and Mary Cole, and then significantly expanded by Bob Leedom into Super Star Trek in 1974. Because of that long fork-and-port history, a Univac installation could easily have had a local or adapted version with commands such as Impulse and Warp separated out, different map symbols, or different alert text. 

That also explains why your memory of bell characters, teletype-friendly displays, and paper-tape workflow fits so well. Ahl’s 1978 book even thanks Teletype Corporation for the teleprinter used for listings and runs, which strongly matches the era and style you remember. 

Is source available online?
Yes, published source listings are online for the classic family:

Super Star Trek listing and instructions at Atari Archives. 

A modern repository with a faithful port of the Ahl/Leedom version. 

A BASIC STARTREK.BAS sample in an open repository. 

What I did not find is a clearly identified Univac 1102/1103-specific source listing matching your exact command vocabulary and display conventions. The closest documented lineage I found is the standard Star Trek / Super Star Trek line, not a confirmed Univac-only edition. 

Legal/release angle for your MIT clone
For an MIT-licensed clean-room clone, the safe approach is:

Good to reuse
the high-level game idea: galaxy/quadrant/sector map

the general mechanics: scan, move, fight Klingons, dock, manage energy/time

generic command names like SRS, LRS, PHA, TOR, WARP, IMPULSE

Better not to copy
the original BASIC source listing

distinctive help text, alert strings, and flavor prose

exact symbol set and exact UI phrasing from a published version

exact balancing constants unless you intentionally want compatibility

That caution matters because the 1978 Ahl book was published under copyright, not as public domain. 

Recommended architecture for your clone
Given your goal, I would not try to reproduce one exact historical listing. I would build a memory-faithful clean-room variant with these layers:

High-level design
Core world model

galaxy: 8×8 quadrants

each quadrant: 8×8 sectors

entities: Enterprise, Klingons, stars, starbases, maybe planets

Ship state

energy

shields

torpedoes

stardate / turns remaining

current quadrant and sector

damage flags

Command parser

accept full words and short forms

examples: SRS, LRS, WARP, IMP, PHA, TOR, SHE, DAM, HELP

Display engine

pure text

optional bell on red alert

teletype-friendly fixed-width output

no cursor control required

Persistence

optional SAVE / LOAD

for period feel, serialize to printable text so it could conceptually be paper-taped

Nonfunctional goals
teletype-friendly latency and formatting

deterministic optional seed for demos

very small code footprint

portable to your BASIC interpreter subset

A clean-room command set that fits your memory
I would use this as the initial spec:

Command	Meaning
SRS	short range scan of current sector grid
LRS	long range scan of surrounding quadrants
WARP qx,qy or WARP course,factor	move between quadrants
IMP x,y or IMP course,distance	move within current quadrant
PHA dir,energy	fire phasers
TOR dir	launch torpedo
SHE amount	assign shield energy
DAM	damage report
STA	ship status
MAP	visited-galaxy record
HELP	command summary
QUIT	abandon mission
That gives you the feel you remember while avoiding a verbatim clone of the Ahl/Leedom UI.

A memory-faithful SRS/LRS design
For your version, I would implement:

SRS
8×8 local grid

row/column labels

symbols such as:

E Enterprise

K Klingon

* star

B base

. empty

That matches your memory better than the published (*), +++, and >!< symbols. The published game used more ornate markers, but a Univac/teletype-local variant could easily have simplified them. 

LRS
3×3 surrounding quadrant report

each cell shows:

Klingons

bases

stars

visited marker

example cell format: K1/B0/S7 or compressed 107

optionally append V for visited

That keeps the classic mechanic while matching your recollection that visited state may have shown up.

Win/lose conditions
The historically grounded objective is:

win: destroy all Klingons before time runs out

lose: ship destroyed, stranded, or mission timer expires

That is the clearest fit to the classic game family. 

Best practical path
I would treat the online Super Star Trek sources as reference material for lineage only, then write a new spec from your remembered play experience:

Version 0
SRS, LRS, WARP, IMP, PHA, TOR, HELP

random galaxy

bell + *** RED ALERT *** when entering hostile quadrant

simple victory condition: eliminate all Klingons

Version 1
SHE, DAM, SAVE, LOAD

starbases for refuel/rearm/repair

visited map memory

Version 2
richer text flavor

named quadrants

difficulty levels

optional “paper tape” save format

Bottom line
Yes: the source family is online, and the closest known ancestor is almost certainly Super Star Trek or one of its descendants, but I did not find a verified Univac-specific listing for your exact remembered version. A clean-room MIT clone is very doable if you avoid copying source and distinctive text from the published Ahl/Leedom versions. 

A strong next step is to write a one-page clean-room game spec based on your memory, using the command set above, and only then implement it in your 1970s-style BASIC.




