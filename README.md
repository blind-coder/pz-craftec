# Long-Term Crafting Projects (CrafTecs)

This mod is a complete overhaul of the building worldobjects mechanics (like
walls, doors and such).

# Current state

The mod is fully functional as of IWBUMS 34.something.

# Mechanics

The mod requires you to start CrafTecs (working name) on squares, then add
parts like planks and nails. After that, you can start working on the object.
If you only have half of the necessary parts, you can start building the object
up to 50% completion (or whatever fraction of parts you have).

Objects take a LOT longer than they did before. Walls take half an hour, stairs
four hours, crates one hour and so on. It always felt weird putting up walls
and stairs in minutes.  
To counterbalance that long time, you can stop the project at any time and
resume working on it later. You can even share the work between different
people!  
Everyone working on the object will get .1 XP for the relevant skill (or for
Carpentry if skill is "any") per minute. Relevant multipliers will still
apply.

The code also allows for objects to require certain level in different skills
and even allows for certain profession. This way you could, for example,
require a nurse with experience in Blunt-Maintenance to build a certain
object.  
You can also require MULTIPLE professions / skilllevels for a single object.

You can also require different tools to build things. Hammers, saws,
blowtorches, a waterscale, a pen, a piece of paper, anything!

# Project Goal

Providing an in-game mechanism for crafting with the following properties:

- Can be interrupted and resumed as necessary (done)
- CrafTecs can require multiple professions or Traits, requiring players to
  work together to finish them (done)
- Optional: Players may try a CrafTec without the required skill, but have only
  a Player.SkillLvl in CrafTec.RequiredSkillLvl chance to succeed, on fail: parts
  break and need to be re-acquired (tbd)
