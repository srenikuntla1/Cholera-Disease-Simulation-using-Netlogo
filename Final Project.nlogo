turtles-own
  [ sick?                ;; if true, the turtle is infectious
    vaccinated?          ;; if true, the turtle is already vaccinated and remaining immunity is set to -1
    doses-received       ;; Number of doses recieved by humans
    infectious-time      ;; how long, in weeks, the turtle has been infectious
    at-home?             ;; if it is true, the human
    single-dose-effectiveness?
    two-doses-effectiveness?
  ]

globals
  [ %infected            ;; what % of the population is infected
    %vaccinated          ;; what % of the population is vaccinated
    stream-patches       ;; represents the flow of river
    stream-width         ;; width of the stream
    stream-flow          ;; Direction of water flow (0 to 360 degrees)ticks / 7
    number-humans-per-house ;; number of humans per house
    %single-dose-effectiveness
    %two-doses-effectiveness
  ]

;; The setup is divided into four procedures
to setup
  clear-all
  reset-ticks ;; initialize tick counter
  ;; create-village
  setup-humans
  ;; setup-stream
  ask turtles [ setup-stream-turtle ]
  ;; setup-water-bodies
  setup-houses
  ;; create-humans-for-houses ;; create humans for each house
  update-display
end

to setup-stream-turtle
  if ticks = 0 [
    ;; Only execute the following during the first tick
    set stream-width 5    ;; Adjust the width of the stream
    set stream-patches []    ;; Adjust the direction of water flow (90 degrees = east)

    ;; create a continuous stream of patches
    let stream-length 60
    let start-xcor min-pxcor
    let end-xcor max-pxcor

    ;; Loop to create the stream patches
    repeat stream-length [
      let ycor-value sin(start-xcor) * stream-width / 2
      let current-patch patch start-xcor ycor-value
      set stream-patches lput current-patch stream-patches
      set start-xcor start-xcor + 1
    ]

    ;; setting color of the stream patches
    ask patches with [member? self stream-patches] [ set pcolor blue ]
  ]
end

to go
  ask turtles [
    get-older
    move
    if sick? [
      infect
      recover-or-die
    ]
    get-vaccine
  ]
  move-turtles
  update-global-variables
  update-display
  tick

  ;; stop the simulation when all the turtles are vaccinated
  if all? turtles[vaccinated?] [
    stop
  ]

end


;; We create a variable number of humans of which some of them are infected,
;; and distribute them randomly
to setup-humans
  create-turtles initial-population
    [ setxy random-xcor random-ycor
      set infectious-time 0
      set sick? false
      set vaccinated? false
      set size 2  ;; size of each human
      set shape "person"
   ]
  ask n-of initially-infected turtles
    [ get-sick ]

  ;; set turtles based on the vaccination slider value
  let current-vaccine-chance (vaccination-chance)

  ;; Number of turtles to vaccinate based on the slider
  let turtles-to-vaccinate round ( ( current-vaccine-chance / 100 ) * count turtles)

  ;;print (word "Number of turtles to vaccinate: " turtles-to-vaccinate)

  ;; Print information about turtles before vaccination
  ;; print (word "Number of turtles: " count turtles)
  ;; print (word "Number of sick turtles: " count turtles with [sick?])
  ;; print (word "Number of vaccinated turtles: " count turtles with [vaccinated?])

  ask n-of turtles-to-vaccinate turtles [
    set sick? false
    set infectious-time 0
    set vaccinated? true
    set color blue ;; set initially vaccinated turtles to color blue
  ]
  ;; Set at-home? for turtles not vaccinated and not sick
  ask turtles [
    set at-home? true
  ]
  ;; Print information about turtles after vaccination
  ;; print (word "Number of turtles: " count turtles)
  ;; print (word "Number of sick turtles: " count turtles with [sick?])
  ;; print (word "Number of vaccinated turtles: " count turtles with [vaccinated?])

  ; Set initial values for the effectiveness monitors
  set %single-dose-effectiveness 0
  set %two-doses-effectiveness 0
end

;; to setup-houses
  ;; ask patches with [ pxcor = 1 and pycor = 1 ]
    ;; [ set pcolor red ]
;; end


to setup-stream
  if ticks = 0 [
    ;; Only execute the following during the first tick
    set stream-width 10    ;; Adjust the width of the stream
    set stream-flow 90    ;; Adjust the direction of water flow (90 degrees = east)

    ;; Create a straight stream of patches
    set stream-patches patches in-cone stream-flow (stream-width / 2)
    ask stream-patches [set pcolor blue]
    ;; Skip the stream setup on subsequent ticks
  ]
end

to move-turtles
  ;; Turtles move along the stream
  ask turtles [
    if at-home? = 0 [
      let next-patch one-of patches in-radius 1 with [member? self stream-patches]
      if next-patch != nobody [
        move-to next-patch
        set at-home? false
        ;; Check if the turtle is in contact with the stream and get sick from water
        ifelse [pcolor] of next-patch = blue [
          get-sick-from-water
        ] [
          ;; move-to next-patch
          set at-home? true
        ]
      ]
    ]
  ]
end

to setup-houses
  repeat number-houses [

    let potential-house-patches patches with [
      not member? self stream-patches
    ]
    let house-patch one-of potential-house-patches
    ask house-patch [
      set pcolor orange
    ]
    ;; create 3 to 5 humans per house
    create-turtles (3 + random 3) [
      setxy random-xcor random-ycor
      set infectious-time 0
      set sick? false
      set vaccinated? false
      set size 2  ;; size of each human
      set shape "person"
    ]
  ]
end




to get-sick ;; turtle procedure
  if not vaccinated? [
    set sick? true
  ]
end

to recover ;; human procedure
  if doses-received = 2 [
    set sick? false
    set infectious-time 0
    set doses-received 0 ; Resetting doses for future infections
  ]
end

;; Humans move randomly.
to move ;; turtle procedure
  rt random 100
  lt random 100
  fd 1
end

to update-global-variables
  if count turtles > 0
    [ set %infected (count turtles with [ sick? ] / count turtles) * 100
      set %vaccinated (count turtles with [ vaccinated? ] / count turtles) * 100 ]
end



to get-sick-from-water ;; sick due to water contact
  if random-float 100 < water-infectivity[
    print "Infected from water!"
    get-sick
  ]
    print "Not infected from water."
end

;; If a turtle is sick, it infects other humans on the same patch.
;; Vaccinated humans don't get sick.
to infect ;; turtle procedure
  ask other turtles in-radius (infection-radius) with [ not sick? and not vaccinated? ]
    [ if random-float 100 < infectivity [
      ifelse [pcolor] of patch-here = orange [
        get-sick-from-water
      ]
      [ get-sick ] ]
  ]
end

;;Human counting variables are advanced.
to get-older ;; turtle procedure
  ;; Human die of old age once their age exceeds the
  ;; lifespan (set at 50 years in this model).
  if sick? [ set infectious-time infectious-time + 1 ]
end

;; Once the turtle has been sick long enough, it
;; either recovers or it dies.
to recover-or-die ;; turtle procedure
  if sick? [
  if infectious-time > death-onset * 7 [                   ;; If the turtle has survived past the virus' duration, then
     if random-float 100 < lethality [ die ] ]             ;; it has a chance to die.
  if infectious-time > start-of-recovery [                 ;; After the start of recovery, then the turtle
     if random-float 100 < recovery-chance [ recover ] ]   ;; has a chance to recover.
  ]
end

;; After the start-of-vaccination, there is a chance
;; that a healthy individual gets vaccinated.
to get-vaccine
  ;; print "get-vaccine is being called"
  if ticks > start-of-vaccination * 7 [
    let current-vaccination-chance vaccination-chance

    ;; using Vaccination chance from the slider

    set current-vaccination-chance (vaccination-chance)

    ;; Number of turtles to vaccinate based on the slider
    let turtles-to-vaccinate count turtles with [not sick? and not vaccinated?]
    ;; Print information about turtles
    ;; print (word "Number of turtles: " count turtles)
    ;; print (word "Number of sick turtles: " count turtles with [sick?])
    ;; print (word "Number of vaccinated turtles: " count turtles with [vaccinated?])

    let number-of-vaccinate round ( ( current-vaccination-chance / 100 ) * turtles-to-vaccinate)

    ;; Vaccinating specified number of turtles
    let turtles-to-vaccinate-list n-of number-of-vaccinate turtles with [ not sick? and not vaccinated? ]
    ;; print ( word "turtles to vaccinate: " count turtles-to-vaccinate-list)
    ;; print (word "Number of turtles: " count turtles)
    ;; print (word "Number of sick turtles: " count turtles with [ not sick?] )
    ;; print (word "Number of vaccinated turtles: " count turtles with [ vaccinated? ] )

    ifelse turtles-to-vaccinate > 0 [
    ;; Calculate effectiveness
    let single-dose-effectiveness (count turtles with [vaccinated? and doses-received = 1] / turtles-to-vaccinate * 100 )
    let two-doses-effectiveness (count turtles with [vaccinated? and doses-received = 2] / turtles-to-vaccinate * 100 )

    ;; Update global variables
    set %single-dose-effectiveness single-dose-effectiveness
    set %two-doses-effectiveness two-doses-effectiveness
    ] [
      ;; set effectiveness when there is no turtles to vaccinate
      set %single-dose-effectiveness 0
      set %two-doses-effectiveness 0
    ]
    ask turtles-to-vaccinate-list[
      print (word "Before vaccination - Turtle " who ": sick? " sick? ", vaccinated? " vaccinated?)
      set sick? false
      set infectious-time 0
      set vaccinated? true
      print (word "After vaccination - Turtle " who ": sick? " sick? ", vaccinated? " vaccinated?)
      set doses-received doses-received + 1 ; Incrementing the number of doses received
    ]

    if not sick? and random-float 100 < vaccination-chance [
      set sick? false
      set infectious-time 0
      set vaccinated? true
      set doses-received doses-received + 1 ; inCrement doses received
    ]
  ]
end

to update-display

  ask turtles
    [
      set color ifelse-value sick? [ red ] [ ifelse-value vaccinated? [ sky ] [ green ] ]
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
238
11
878
445
-1
-1
10.373
1
10
1
1
1
0
1
1
1
-30
30
-20
20
1
1
1
ticks
30.0

SLIDER
11
47
221
80
initial-population
initial-population
50
300
300.0
1
1
people
HORIZONTAL

BUTTON
18
136
82
169
Setup
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
11
89
219
122
initially-infected
initially-infected
1
40
7.0
1
1
people
HORIZONTAL

PLOT
239
462
679
693
Populations
days
people
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"sick" 1.0 0 -2674135 true "" "plot count turtles with [ sick? ]\n"
"vaccinated" 1.0 0 -11221820 true "" "plot count turtles with [ vaccinated? ]"
"susceptible" 1.0 0 -13840069 true "" "plot count turtles with [ not sick? and not vaccinated? ]"
"dead" 1.0 0 -16777216 true "" "plot initial-population - count turtles"

MONITOR
724
465
811
510
NIL
%infected
1
1
11

MONITOR
724
525
811
570
NIL
%vaccinated
1
1
11

MONITOR
724
583
812
628
weeks
ticks / 7
1
1
11

SLIDER
12
196
210
229
infectivity
infectivity
0
99.9
56.8
0.1
1
%
HORIZONTAL

SLIDER
12
309
211
342
recovery-chance
recovery-chance
0
99.9
35.3
0.1
1
%
HORIZONTAL

SLIDER
12
348
211
381
death-onset
death-onset
0
40
2.0
1
1
weeks
HORIZONTAL

SLIDER
12
271
210
304
lethality
lethality
0
99.9
32.2
0.1
1
%
HORIZONTAL

BUTTON
95
136
216
169
Run Simulation!
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

SLIDER
12
429
212
462
start-of-vaccination
start-of-vaccination
1
200
2.0
1
1
weeks
HORIZONTAL

SLIDER
12
469
212
502
vaccination-chance
vaccination-chance
1
99.9
11.4
0.1
1
%
HORIZONTAL

SLIDER
12
234
210
267
infection-radius
infection-radius
1
5
2.0
0.5
1
spaces
HORIZONTAL

SLIDER
12
387
211
420
start-of-recovery
start-of-recovery
0
100
51.0
1
1
days
HORIZONTAL

SLIDER
1057
65
1229
98
water-infectivity
water-infectivity
0
100
38.0
1
1
NIL
HORIZONTAL

SLIDER
1059
124
1231
157
infection-radius
infection-radius
0
100
2.0
1
1
NIL
HORIZONTAL

SLIDER
1062
197
1235
230
water-body-count
water-body-count
0
30
5.0
1
1
NIL
HORIZONTAL

SLIDER
1063
335
1235
368
number-houses
number-houses
0
100
17.0
1
1
NIL
HORIZONTAL

MONITOR
1031
415
1236
460
%single-dose-effectiveness
%single-dose-effectiveness
2
1
11

MONITOR
1528
407
1733
452
%two-doses-effectiveness
%two-doses-effectiveness
2
1
11

PLOT
884
468
1366
842
Single Dose Effectiveness
days
%effectiveness
0.0
200.0
0.0
100.0
true
false
"" ""
PENS
"single dose" 1.0 1 -13345367 true "" "plot %single-dose-effectiveness"

PLOT
1382
468
1860
838
two doses effectivity
days
%effectiveness
0.0
200.0
0.0
100.0
true
false
"" ""
PENS
"Two dose Effectiveness" 1.0 1 -11783835 true "" "plot %two-doses-effectiveness"

@#$#@#$#@
## WHAT IS IT?

This is a Susceptible-Infected-Vaccinated-Dead (SIVD) model implemented in NetLogo.

## HOW IT WORKS

This model shows the interaction of susceptible, infected, vaccinated, and dead people as the pandemic goes on.

Here are the four classes of people:
1. Susceptible (S): The individuals of that can be infected by COVID-19. They may be infected or immune to the disease if they get the vaccine.
2. Infected (I): The individuals that are infected by COVID-19. They may be cured and become susceptible again or die from the disease.
3. Vaccinated (V): The individuals who got the vaccine for COVID-19 and become immune to the disease.
4. Dead (D): The individuals who died due to the disease.

## HOW TO USE IT

We can set the initial parameters of the simulation:
1. Initial Population: How many people in the population initially. This value ranges from 50 to 300 and can be increased in increments od 1.
2. Initially Infected: How many people get infected at the start of the simulation. This value ranges from 1 to 40 and can be increased in increments of 1.

From there, we can modify the parameters of COVID-19:
1. Infectivity: This value ranges from 0% to 99.9% and can be increased in increments of 0.1%. 
2. Infection Radius: Susceptible people within the infection radius may get infected. Its value ranges from 1 to 5 spaces and can be increased in increments of 0.5 spaces.
3. Lethality: Its value ranges from 0% to 99.9% and can be increased in increments of 0.1%.
4. Death Onset: After this period, the infected person has a chance to die every single day, depending on the disease’s lethality. Its value ranges from 1 week to 40 weeks and can be increased in increments of 1 week.
5. Recovery Chance: This value ranges from 0% to 99.9% and can be increased in increments of 0.1%.
6. Start of Recovery: After this period, the infected person has a chance to recover every single day, depending on the disease’s recovery chance. Its value ranges from 1 week to 40 weeks and can be increased in increments of 1 day.
7. Vaccination Chance: Its value ranges from 0% to 99.9% and can be increased in increments of 0.1%.
8. Start of Vaccination: Sets the start of the vaccination period, where susceptible people get vaccinated and therefore become immune to the disease. Its value ranges from 1 to 200 weeks and can be increased in increments of 1 week.
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.0.4
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
