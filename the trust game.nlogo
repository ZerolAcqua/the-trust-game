globals [
  anyone-vs-dead-score      ;; anyone vs empty gets the score

  good-vs-good-score         ;; the good vs the good gains the score
  good-vs-bad-score          ;; the good vs the bad gains the score
  good-vs-tit-for-tat-score     ;; the good vs the tit-for-tat gains the score

  bad-vs-good-score             ;; the good vs the good gains the score
  bad-vs-bad-score              ;; the good vs the bad gains the score
  bad-vs-tit-for-tat-score      ;; the good vs the tit-for-tat gains the score

  tit-for-tat-vs-good-score            ;; the good vs the good gains the score
  tit-for-tat-vs-bad-score             ;; the good vs the bad gains the score
  tit-for-tat-vs-tit-for-tat-score     ;; the good vs the tit-for-tat gains the score
]

patches-own [
  score           ;; scores of cells
  good?           ;; pink cells
  bad?            ;; violet cells
  tit-for-tat?    ;; cyan cells
  dead?           ;; empty cells
  good-neighbors  ;; counts how many neighboring cells are good
  bad-neighbors   ;; counts how many neighboring cells are bad
  tit-for-tat-neighbors   ;; counts how many neighboring cells are tit-for-tat
  dead-neighbors         ;; counts how many neighboring cells are tit-for-tat
]


;; these functions are to set up the model
to setup-blank    ;; clear the patch
  clear-all
  ask patches
    [ cell-death ]
  reset-ticks
end

to setup-random    ;; set people randomly
  clear-all
  ask patches
    [ let rand random-float 1.0
      ifelse rand < the-good-density
      [cell-good-birth]
      [ifelse rand < the-good-density + the-bad-density
         [cell-bad-birth]
        [
          ifelse rand < the-good-density + the-bad-density + the-tit-for-tat-density
          [cell-tit-for-tat-birth]
          [cell-death]
        ]
      ]
    ]
  reset-ticks
end

;; these functions are original or old and will be delete
to cell-birth  ;; patch procedure
  set good? true
  set bad? false
  set pcolor pink
end

to cell-aging  ;; patch procedure
  set good? false
  set bad? true
  set pcolor violet
end

to old-round-over  ;; old function

  ask patches[
    set score score / 8
    if score < 1
    [cell-death]
  ]
  ask patches[set score 0]
  regeneration
end



;; these functions are to control the behavior of people
to cell-gain-score   ;; patch procedure
  if good? = true
    [set score anyone-vs-dead-score * dead-neighbors + good-vs-good-score * good-neighbors + good-vs-bad-score * bad-neighbors + good-vs-tit-for-tat-score *  tit-for-tat-neighbors ]
  if bad? = true
    [set score anyone-vs-dead-score * dead-neighbors + bad-vs-good-score * good-neighbors + bad-vs-bad-score * bad-neighbors + bad-vs-tit-for-tat-score *  tit-for-tat-neighbors]
  if tit-for-tat? = true
    [set score anyone-vs-dead-score * dead-neighbors + tit-for-tat-vs-good-score * good-neighbors + tit-for-tat-vs-bad-score * bad-neighbors + tit-for-tat-vs-tit-for-tat-score *  tit-for-tat-neighbors]
  set score score / rounds
end

to round-over  ;;

  if count patches with[dead? = false] > 10
  [
    ;; sort the patches by the score
    let score-list sort-by [ [a b] -> [score] of a < [score] of b ] patches with[dead? = false]
    let list-length length score-list
    let list-erase-length list-length * erase-rate  ;;TODO
    let num 0

    while [num < list-erase-length]
    [
      ask item num score-list [cell-death]
      set num num + 1
    ]
  ]
  regeneration
  ask patches[set score 0]
end

to regeneration
  if count patches with[dead? = false] != 0
  [
    let the-good-rate count patches with [good? = true] / count patches with[dead? = false]
    let the-bad-rate count patches with [bad? = true] / count patches with[dead? = false]
    let the-tit-for-tat-rate count patches with [tit-for-tat? = true] / count patches with[dead? = false]
    ask patches[
      if dead? = true
      [
        if random-float 1 < regeneration-rate  ;;TODO
        [let sum-people good-neighbors + bad-neighbors + tit-for-tat-neighbors
          if sum-people != 0
          [
            ;; weighted probability
            let pro-good neightbor-effect-weight * good-neighbors / sum-people + (1 - neightbor-effect-weight) * the-good-rate
            let pro-bad neightbor-effect-weight * bad-neighbors / sum-people + (1 - neightbor-effect-weight)  * the-bad-rate
            let pro-tit-for-tat neightbor-effect-weight * tit-for-tat-neighbors / sum-people + (1 - neightbor-effect-weight)  * the-tit-for-tat-rate

            let rand random-float 1.0
            ifelse rand < pro-good
            [cell-good-birth]
            [ifelse rand < pro-good + pro-bad
              [cell-bad-birth]
              [
                if rand < pro-good + pro-bad + pro-tit-for-tat
                [
                  cell-tit-for-tat-birth
                ]
              ]
            ]
          ]
        ]
      ]
    ]
  ]
end


;; these functions are to generate different types of people
to cell-good-birth
  set good? true
  set bad? false
  set tit-for-tat? false
  set dead? false
  set score 0
  set pcolor pink
end

to cell-bad-birth
  set good? false
  set bad? true
  set tit-for-tat? false
  set dead? false
  set score 0
  set pcolor violet
end

to cell-tit-for-tat-birth
  set good? false
  set bad? false
  set tit-for-tat? true
  set dead? false
  set score 0
  set pcolor cyan
end

;; this function is to erase the people
to cell-death  ;; patch procedure
  set good? false
  set bad? false
  set tit-for-tat? false
  set dead? true
  set score 0
  set pcolor black
end

;; these functions are to calculate the single-game scores in diferent situations
;; between different types of people
to calculate-round-score
  set anyone-vs-dead-score 0

  set good-vs-good-score coop-vs-coop * rounds
  set good-vs-bad-score coop-vs-cheat * rounds
  set good-vs-tit-for-tat-score calculate-good-vs-TFT-round-score

  set bad-vs-good-score cheat-vs-coop * rounds
  set bad-vs-bad-score cheat-vs-cheat * rounds
  set bad-vs-tit-for-tat-score cheat-vs-coop + cheat-vs-cheat * (rounds - 1)

  set tit-for-tat-vs-good-score coop-vs-coop * rounds
  set tit-for-tat-vs-bad-score coop-vs-cheat + cheat-vs-cheat * (rounds - 1)
  set tit-for-tat-vs-tit-for-tat-score calculate-TFT-vs-TFT-round-score
end

to-report calculate-TFT-vs-TFT-round-score
  let correct-vs-correct coop-vs-coop * rounds
  let mistake-vs-mistake cheat-vs-cheat * rounds
  ;; correct-vs-mistake and correct-vs-mistake
  ;; are considered together to simplify the calculation
  let correct-and-mistake ( coop-vs-cheat + cheat-vs-coop) * rounds / 2
  report  (1 - mistake-rate) * (1 - mistake-rate) * correct-vs-correct
         + 2 * (1 - mistake-rate) * mistake-rate * correct-and-mistake
         + mistake-rate * mistake-rate * mistake-vs-mistake
end


to-report calculate-good-vs-TFT-round-score
  let correct-vs-correct coop-vs-coop * rounds
  let mistake-vs-mistake 0
  let correct-vs-mistake 0
  let mistake-vs-correct 0

  ifelse rounds > 2
  [
    set mistake-vs-mistake cheat-vs-cheat * 1 + coop-vs-cheat * 1 + coop-vs-coop * (rounds - 2)
    set correct-vs-mistake coop-vs-cheat * 1 + coop-vs-coop * (rounds - 1)
    set mistake-vs-correct cheat-vs-coop * 1 + coop-vs-cheat * 1 + coop-vs-coop * (rounds - 2)
  ]
  [
    ifelse rounds > 1
    [
      set mistake-vs-mistake cheat-vs-cheat * 1 + coop-vs-cheat * 1
      set correct-vs-mistake coop-vs-cheat * 1 + coop-vs-coop * (rounds - 1)
      set mistake-vs-correct cheat-vs-coop * 1 + coop-vs-cheat * 1
    ]
    [
      set mistake-vs-mistake cheat-vs-cheat * 1
      set correct-vs-mistake coop-vs-cheat * 1
      set mistake-vs-correct cheat-vs-coop * 1
    ]
  ]


  report  (1 - mistake-rate) * (1 - mistake-rate) * correct-vs-correct
         + (1 - mistake-rate) * mistake-rate * correct-vs-mistake
         + mistake-rate * (1 - mistake-rate) * mistake-vs-correct
         + mistake-rate * mistake-rate * mistake-vs-mistake
end


to go
  calculate-round-score
  ;; count the number of neighbors with a certain type
  ask patches
    [ set good-neighbors count neighbors with [good?]
      set bad-neighbors count neighbors with [bad?]
      set tit-for-tat-neighbors count neighbors with [tit-for-tat?]
      set dead-neighbors  count neighbors with [dead?] ]

  ask patches
    [cell-gain-score]

  round-over

  tick
end

to draw-cells [target-color]
  if mouse-down? [
    ask patch mouse-xcor mouse-ycor [
      ifelse target-color = pink
        [cell-good-birth]
        [ifelse target-color = violet
          [cell-bad-birth]
          [ifelse target-color = cyan
            [cell-tit-for-tat-birth]
            [cell-death]]]]
    display
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
435
25
840
431
-1
-1
3.9703
1
10
1
1
1
0
1
1
1
-50
49
-50
49
1
1
1
ticks
15.0

SLIDER
51
62
242
95
the-good-density
the-good-density
0.0
1.0
0.85
0.01
1
NIL
HORIZONTAL

BUTTON
261
102
389
135
NIL
setup-random
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
562
523
691
556
go-forever
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

BUTTON
261
63
389
96
NIL
setup-blank
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

TEXTBOX
52
470
151
488
Edit cells
11
0.0
0

BUTTON
52
487
180
520
draw pink cells
draw-cells pink
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
52
527
180
560
draw violet cells
draw-cells violet\n
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
198
487
326
520
draw cyan cells 
draw-cells cyan\n
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
51
101
242
134
the-bad-density
the-bad-density
0
1
0.1
0.01
1
NIL
HORIZONTAL

SLIDER
52
196
242
229
rounds
rounds
1
20
20.0
1
1
NIL
HORIZONTAL

TEXTBOX
36
18
275
54
Initialization setting
17
0.0
1

SLIDER
51
140
241
173
the-tit-for-tat-density
the-tit-for-tat-density
0
1
0.05
0.01
1
NIL
HORIZONTAL

TEXTBOX
52
44
152
62
Basic setting
12
0.0
1

TEXTBOX
404
494
554
512
Run this model
17
0.0
1

BUTTON
198
528
326
561
erase
draw-cells black\n
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
416
523
545
556
go-once
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

TEXTBOX
52
178
202
196
Rule setting
12
0.0
1

MONITOR
902
345
1057
390
thr good
count patches with [good? = true] / count patches with[dead? = false]
3
1
11

MONITOR
1092
345
1248
390
the bad
count patches with [bad? = true] /  count patches with[dead? = false]
3
1
11

MONITOR
1279
345
1435
390
the tit-for-tat
count patches with [tit-for-tat? = true] /  count patches with[dead? = false]
3
1
11

PLOT
901
29
1434
321
Proportion of Different Types
NIL
NIL
0.0
10.0
0.0
1.0
true
false
"" ""
PENS
"the good" 1.0 0 -2064490 true "" "plot count patches with[good? = true] / count patches with[dead? = false]"
"the bad" 1.0 0 -8630108 true "" "plot count patches with[bad? = true] / count patches with[dead? = false]"
"the tit-for-tat" 1.0 0 -11221820 true "" "plot count patches with[tit-for-tat? = true] / count patches with[dead? = false]"
"pen-3" 1.0 0 -16777216 true "" "plot count patches with[dead? = false] / count patches"

SLIDER
52
237
190
270
coop-vs-coop
coop-vs-coop
-5
5
0.0
1
1
NIL
HORIZONTAL

SLIDER
202
278
340
311
cheat-vs-cheat
cheat-vs-cheat
-5
5
0.0
1
1
NIL
HORIZONTAL

SLIDER
52
277
190
310
coop-vs-cheat
coop-vs-cheat
-5
5
-2.0
1
1
NIL
HORIZONTAL

SLIDER
202
237
341
270
cheat-vs-coop
cheat-vs-coop
-5
5
2.0
1
1
NIL
HORIZONTAL

SLIDER
53
432
243
465
mistake-rate
mistake-rate
0
1
0.0
0.1
1
NIL
HORIZONTAL

SLIDER
53
394
244
427
neightbor-effect-weight
neightbor-effect-weight
0
1
0.8
0.1
1
NIL
HORIZONTAL

SLIDER
53
317
243
350
erase-rate
erase-rate
0
1
0.1
0.1
1
NIL
HORIZONTAL

SLIDER
53
355
243
388
regeneration-rate
regeneration-rate
0
1
0.5
0.01
1
NIL
HORIZONTAL

@#$#@#$#@
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

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.2.2
@#$#@#$#@
setup-random
repeat 67 [ go ]
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
