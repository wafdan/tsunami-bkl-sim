;; USE EXTENSION 
extensions [gis] 

;;*******************************************************************
;; DECLARING VARIABLES
;;*******************************************************************
;; GLOBAL VARIABLES

globals [ 
   korban-shelter
   korban-hilang 
   korban-shelter-kids
   korban-hilang-kids
   korban-shelter-teens
   korban-hilang-teens
   korban-shelter-adults
   korban-hilang-adults
   korban-shelter-elders
   korban-hilang-elders
   min-safe-distance
    
   decided-kids
   decided-teens
   decided-adults
   decided-elders
    
   start-ticks 
   sea-patches
   road-patches
   urban-patches
   
   adultar-patches
   kidsar-patches
   
   Land
   Sea 
   Road 
   Building 
   Landuse 
   TEB 
   Exits
   AdultAr ;area distribusi orang dewasa terbanyak
   KidsAr ;area distribusi anak2 terbanyak
   
   paths-dataset 
   perimeter-dataset 
   island-dataset 
   canal-dataset 
   stopgobutton?
   
   scale
   Cmax-ped
   
   start
   target
   space-color
   heuristic
   
   agent-done-astar
  ] 

breed [ nodes node ]
breed [ points point]
breed [ shelters shelter]
breed [ shelter-labels shelter-label ]
breed [ exitpoints exitpoint]
breed [ exitpoint-labels exitpoint-label ]

; jenis2 agen
breed [humans human]
breed [kids kid]
breed [teens teen]
breed [adults adult]
breed [elders elder]

breed [motors motor]
breed [cars car]

humans-own [to-node cur-link speed]
kids-own [dim speed to-node cur-link goal stage path backupath Len td initpos] ;td = time of departure
teens-own [dim speed to-node cur-link goal stage path backupath Len td initpos]
adults-own [dim speed to-node cur-link goal stage path backupath Len td initpos]
elders-own [dim speed to-node cur-link goal stage path backupath Len td initpos]

cars-own [to-node cur-link speed]
motors-own [to-node cur-link speed]
shelters-own[id capacity num-inside num-kids-ins num-teens-ins num-adults-ins num-elders-ins]
shelter-labels-own[which-shelter]
exitpoints-own[capacity num-inside]
exitpoint-labels-own[which-exitpoint]

patches-own [is-road? lanes 
             parent open? f g h zt vx vy vt] ;astar related: open? 0=NA,1=open,2=closed.

to startup
  set jam-mulai 7
  set menit-mulai 45
end

;; SETUP PROCEDURES 
to setup
  clearAll
  ifelse (rep-gen) ;jika ada repetisi
  [ 
    if idx-awal = "" [ set idx-awal 0 ]
    if idx-akhir = "" [ set idx-akhir 0 ]
    
    
    if(idx-awal < idx-akhir)
    [
      let numrep  (idx-akhir - idx-awal + 1)
      let curidx idx-awal
      
      set scale 5; <- katanya sih penting
      set min-safe-distance 5
      ask patches [set pcolor white]
      output-print (word "mulai repetisi")
      
      
      repeat numrep [
        clear-turtles
        clear-patches
        clear-ticks
        reset-ticks
        set scale 5; <- katanya sih penting
        set min-safe-distance 5
        ask patches [set pcolor white]
        
        readGISData ;Read GIS data
        drawGIS ;Draw GIS
        output-print (word "membaca data GIS...")
        
        output-print (word "repetisi indeks ke-" curidx)
        ifelse (load-file?)
        [
          ;import-world user-file
          output-print (word "tidak dapat Load file jika rep-gen masih ON.")
        ]
        [
          ;setup-paths-graph
          setup-shelters-node
          if(use-exit)[ setup-exitpoints-node ]
          ;setup-paths-graph-old
          setup-road-patch
          ;pasang agen2
          load-population
          
          if(pathfind-on-setup) 
          [
            let pedestrians (turtle-set kids teens adults elders)
            ask pedestrians[
              decide-start
              decide-shelter
              decide-road-and-shelter-route curidx
            ]  
          ]
        ]
        ;ask patches [set pcolor green]
        ;set start-ticks get-start-time-ticks-from-inputs;27900
        set Cmax-ped ceiling (0.7 * scale ^ 2)
        display
        
        set curidx curidx + 1
        
      ];end repeat
      output-print (word "repetisi selesai.")
      
    ]
    
  ]
  [ clearAll ;Resets all global variables to zero, and calls clear-ticks, clear-turtles, clear-patches, clear-drawing, clear-all-plots, and clear-output.
    ;drawBgr ;Draw background with google map
    
    set scale 5; <- katanya sih penting
    set min-safe-distance 5
    ask patches [set pcolor white]
    readGISData ;Read GIS data
    drawGIS ;Draw GIS
    output-print (word "membaca data GIS...")
    ifelse (load-file?)
    [
      import-world user-file
      set korban-shelter 0
      set korban-hilang 0 
      set korban-shelter-kids 0
      set korban-hilang-kids 0
      set korban-shelter-teens 0
      set korban-hilang-teens 0
      set korban-shelter-adults 0
      set korban-hilang-adults 0
      set korban-shelter-elders 0
      set korban-hilang-elders 0
      set decided-kids 0
      set decided-teens 0
      set decided-adults 0
      set decided-elders 0
      let pedestrians (turtle-set kids teens adults elders)
      ask pedestrians[
        if(initpos != 0 and initpos != nobody)[
        move-to initpos  
        ]
      ]
      ask shelters [
        set num-inside 0
        set num-kids-ins 0
        set num-teens-ins 0
        set num-adults-ins 0
        set num-elders-ins 0
      ]
      ask shelter-labels [set label (word "[0]")]
      clear-ticks
      reset-ticks
    ]
    [
      setup-paths-graph
      setup-shelters-node
      if(use-exit)[ setup-exitpoints-node ]
      ;setup-paths-graph-old
      setup-road-patch
      ;pasang agen2
      load-population
      
      if(pathfind-on-setup) 
      [
        let pedestrians (turtle-set kids teens adults elders)
        ask pedestrians[
          decide-start
          decide-shelter
          decide-road-and-shelter-route ""
        ]  
      ]
    ]
    ;ask patches [set pcolor green]
    set start-ticks get-start-time-ticks-from-inputs;27900
    set Cmax-ped ceiling (0.7 * scale ^ 2)
    display
  ]
  set min-safe-distance 1
  ;backup path IF ga kosong
  let pedestrians (turtle-set kids teens adults elders)
   ask pedestrians[
;     if(path != nobody and path != [])
;     [
       set backupath []
       set initpos first path
       show-turtle
;     ]
   ]  

end 

;; GO PROCEDURES 
to go
  ;if (count humans = 0 ) [ stop]
  ;ask humans [move-human speed]
  if (
      ((count kids with [hidden? = false] = 0) and (count teens with [hidden? = false] = 0) and (count adults with [hidden? = false] = 0) and (count elders with [hidden? = false] = 0)) or
      (count shelters with [ num-inside < capacity] = 0)
     )
  [ 
     set korban-shelter (korban-shelter-kids + korban-shelter-teens + korban-shelter-adults + korban-shelter-elders)
     output-type "menit ke-" output-type ceiling (ticks / 60) output-print ": " 
     output-print "terevakuasi"
     output-type " total  " output-type korban-shelter output-print "" 
     output-type " anak   " output-type korban-shelter-kids output-print "" 
     output-type " remaja " output-type korban-shelter-teens output-print "" 
     output-type " dewasa " output-type korban-shelter-adults output-print "" 
     output-type " tua    " output-type korban-shelter-elders output-print "" 
     
     foreach sort-on [id] shelters [
       ask ? 
       [ output-print (word "   shelter " id ":")
         output-print "    terevakuasi"
         output-print (word "    total  " num-inside " [cap " capacity "]")
         output-type  "    anak   " output-type num-kids-ins output-print "" 
         output-type  "    remaja " output-type num-teens-ins output-print "" 
         output-type  "    dewasa " output-type num-adults-ins output-print "" 
         output-type  "    tua    " output-type num-elders-ins output-print "" 
       ]
     ]
     output-print "------------------"
     
     if(pragmagent)[
       if(save-file?)[
         let pedestrians (turtle-set kids teens adults elders)
         ask pedestrians[
             set path backupath
         ]  
         
         ifelse (save-file-name = "")
         [export-world (word "autosave-bkl-sim-export_" date-and-time "-pragma.csv")]
         [ 
           export-world (word save-file-name "-pragma.csv")
          ]
         
       ]
     ]
     
     
     stop
   ]
;  ask kids [move-kid speed]
;  ask teens [move-teen speed]
;  ask adults [move-adult speed]
;  ask elders [move-elder speed] 
  let pedestrians (turtle-set kids teens adults elders)
  ask pedestrians[
    
    
;  let world-envelope gis:world-envelope
    
;    let gis-width 1351 ;(item 1 world-envelope - item 0 world-envelope) 
;    let gis-height 835 ;(item 3 world-envelope - item 2 world-envelope) 
;    
;    let factor max list (gis-width / world-width) 
;                       (gis-height / world-height)
;    
;    ifelse (show-turtle-label)[ 
;      set label (word who 
;        " [" precision (speed * factor) 3 "] " 
;        (distance goal * factor) 
;        ;factor
;        );gis-width "x" gis-height " " factor) 
;      set label-color black ]
;    [set label ""]
;    ifelse member? patch-here urban-patches
;    [set hidden? true][set hidden? false]
   ;;;;;decide-start
   ;;;;;decide-shelter
   
;   let aroad one-of road-patches with-min [distance myself]
;   if (member? patch-here road-patches);(distance aroad > 2 and distance aroad < distance goal)
;   [
;      set goal aroad
;     ]
   
;   set path Astar patch-here goal green 4
;   set Len length path
;if(load-file?)[
   ;;;;;decide-road-and-shelter-route
;]
   ifelse (pathfind-on-setup)
   [
     if(not hidden?)[
       follow-predefined-path
     ]
   ]
   [
     if(not hidden?) [
       decide-start
       decide-shelter
       decide-road
       follow-path
       search-shelter-route 
     ]
   ]
   
   ;decide-road
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;print (word "adult " who " patch-here " patch-here " goal " goal " path[" Len "]: " path)
   ;repeat 5 [ follow-path ]
   ;follow-path
   ;search-shelter-route
   
   
   if ((distance goal < min-safe-distance)) 
   [ 
     if breed = kids [ set korban-shelter-kids korban-shelter-kids + 1]
     if breed = teens [ set korban-shelter-teens korban-shelter-teens + 1]
     if breed = adults [ set korban-shelter-adults korban-shelter-adults + 1]
     if breed = elders [ set korban-shelter-elders korban-shelter-elders + 1]
     
     ;"hantu" agen untuk diload
     ;hide-turtle
     if(initpos != nobody)[
       move-to initpos
     ]
     
     if (member? goal shelters)
     [ let ashelter min-one-of shelters [distance myself]
       increment-in-shelter ashelter self
     ]
     
     if (member? goal exitpoints)
     [ let anexit min-one-of exitpoints [distance myself]
       increment-in-exitpoint anexit
     ]
     
     ask self [ 
       ;stamp
       hide-turtle
       ;die
       ]
   ]
   
  ]
   
  set korban-shelter (korban-shelter-kids + korban-shelter-teens + korban-shelter-adults + korban-shelter-elders)
  if ((ticks != 0) and (ticks mod 300 = 0 )) 
   [ output-type "menit ke-" output-type ceiling (ticks / 60) output-print ": " 
     output-print "terevakuasi"
     output-type " total  " output-type korban-shelter output-print "" 
     output-type " anak   " output-type korban-shelter-kids output-print "" 
     output-type " remaja " output-type korban-shelter-teens output-print "" 
     output-type " dewasa " output-type korban-shelter-adults output-print "" 
     output-type " tua    " output-type korban-shelter-elders output-print "" 
     ;output-type " " output-type (num-humans - count(humans)) output-print " hilang" 
     
     foreach sort-on [id] shelters [
       ask ? 
       [ output-print (word "   shelter " id ":")
         output-print "    terevakuasi"
         output-type  "    total  " output-type num-inside output-print "" 
         output-type  "    anak   " output-type num-kids-ins output-print "" 
         output-type  "    remaja " output-type num-teens-ins output-print "" 
         output-type  "    dewasa " output-type num-adults-ins output-print "" 
         output-type  "    tua    " output-type num-elders-ins output-print "" 
       ]
     ]
     output-print "------------------"
   ]
  tick
end 

;; CLEAR ALL WHEN SETUP
to clearAll
  clear-all ;Resets all global variables to zero, and calls clear-ticks, clear-turtles, clear-patches, clear-drawing, clear-all-plots, and clear-output.
  clear-ticks ;Clears the tick counter.
  reset-ticks ;Resets the tick counter to zero, sets up all plots, then updates all plots (so that the initial state of the world is plotted).
  reset-timer ;Resets the timer to zero seconds.
  clear-links ;Kills all links.
  clear-turtles ;Kills all turtles.
  clear-patches ;Clears the patches by resetting all patch variables to their default initial values, including setting their color to black.
  clear-drawing ;Clears all lines and stamps drawn by turtles.
  clear-all-plots ;Clears every plot in the model.
  clear-output ;Clears all text from the model's output area, if it has one.
end 

to drawBgr
  import-drawing "spatialdata/big_bengkulu.jpg" 
end

to readGISData
  ; SKALA PETA 1:8000 (info dari arcgis)
  ;set Road          gis:load-dataset "spatialdata/road_lineBKL_Buffer.shp" 
  ;set Building      gis:load-dataset "spatialdata/buildingsBKL.shp" 
  ifelse gov-road-only 
  [ set Road     gis:load-dataset "spatialdata/gov_road.shp" ]
  [ set Road     gis:load-dataset "spatialdata/newer_road2.shp" ]
  
  set Building gis:load-dataset "spatialdata/newer_building.shp" 
  set TEB      gis:load-dataset "spatialdata/newer_TEB.shp" 
  set Exits    gis:load-dataset "spatialdata/Exits.shp" 
  set Sea      gis:load-dataset "spatialdata/sea_poly.shp"
  set Land     gis:load-dataset "spatialdata/Landpoly.shp"
  set AdultAr  gis:load-dataset "spatialdata/Area_adult.shp"
  set KidsAr   gis:load-dataset "spatialdata/Area_kids.shp"
  
  ;set Road          gis:load-dataset "spatialdata/newer_road.shp" 
  ;set Building          gis:load-dataset "spatialdata/newer_building.shp" 
  ;set Landuse          gis:load-dataset "spatialdata/new_landuse.shp" 
  

  ;set paths-dataset gis:load-dataset "spatialdata/road_lineBKL_Buffer.shp"
  
  ;set perimeter-dataset gis:load-dataset "acehspatialdata/admin_90_des.shp"
  ;set paths-dataset     gis:load-dataset  "acehspatialdata/JALAN_asli_polyline.shp"
  ;set canal-dataset     gis:load-dataset "acehspatialdata/Sungai_BNA_terbaru.shp"
end 

to setup-road-patch
  ask patches [set is-road? false]
    ask patches gis:intersecting Road 
    [set is-road? true]
    
  ask patches with [is-road? = true] [set pcolor green]
end

to setup-paths-graph
  set-default-shape nodes "circle"
  ask nodes [create-link-with one-of other nodes]
  
  ask nodes [create-link-with one-of points]
  foreach polylines-of Road node-precision [
    (foreach butlast ? butfirst ? [ if ?1 != ?2 [ ;; skip nodes on top of each other due to rounding
      let n1 new-node-at first ?1 last ?1
      let n2 new-node-at first ?2 last ?2
      ask n1 [create-link-with n2]
      
    ]])
  ]
    
  ask nodes [hide-turtle]
end

to setup-shelters-node
  set-default-shape shelters "house"
  
  let shbuilt 0
  
  ; sebelum shelter dibangun dgn looping, diurut-naik dulu berdasarkan hasil penjumlahan xcord dan ycord, 
  ; yg mewakili posisi kiri bawah. nanti dicek 
  ; ini mengga
  
  foreach sort-by 
   [ (item 0 gis:location-of (first (first (gis:vertex-lists-of ?1))))
     + (item 1 gis:location-of (first (first (gis:vertex-lists-of ?1)))) 
     < 
     (item 0 gis:location-of (first (first (gis:vertex-lists-of ?2))))
     + (item 1 gis:location-of (first (first (gis:vertex-lists-of ?2))))
   ] 
   gis:feature-list-of TEB [
    ;gis:set-drawing-color [254 0 0]
    ;gis:fill ? 2.0
    let location gis:location-of (first (first (gis:vertex-lists-of ?)))
    if ((not empty? location) and (shbuilt < num-shelters))
    [ 
       let x (item 0 location)
       let y (item 1 location)
       
       if(
          (shbuilt = 0 and shltr-1) or 
          (shbuilt = 1 and shltr-2) or 
          (shbuilt = 2 and shltr-3) or 
          (shbuilt = 3 and shltr-4) or 
          (shbuilt = 4 and shltr-5) or 
          (shbuilt = 5 and shltr-6) or 
          (shbuilt = 6 and shltr-7) or 
          (shbuilt = 7 and shltr-8) )
       [
         create-shelters 1
         [ 
           set xcor x
           set ycor y
           set size 5.3
           set color red
           set id shbuilt + 1
           ;set label (word "   " num-inside)
           attach-shelter-label who
           
           ;if(shbuilt = 0) [ set capacity 0 ]
           if(shbuilt = 1) [ set capacity 500 ]
           if(shbuilt = 2) [ set capacity 600 ]
           if(shbuilt = 3) [ set capacity 600 ]
           if(shbuilt = 4) [ set capacity 80  ]
           ;if(shbuilt = 5) [ set capacity 0 ]
           if(shbuilt = 6) [ set capacity 150 ]
           if(shbuilt = 7) [ set capacity 360 ]
           
         ]
       ] 
       
       
       set shbuilt (shbuilt + 1)
        
       ;output-type "shelter " output-type (item 0 location) output-print ", " output-print (item 1 location)
     ]
  ]
end

to setup-exitpoints-node
  set-default-shape exitpoints "dot"
  foreach gis:feature-list-of Exits [
    let location gis:location-of (first (first (gis:vertex-lists-of ?)))
    if (not empty? location)
    [ 
       let x (item 0 location)
       let y (item 1 location)
        
       create-exitpoints 1
       [ set xcor x
         set ycor y
         set size 6.3
         set color magenta
         attach-exitpoint-label who
         ]
        ;output-type "shelter " output-type (item 0 location) output-print ", " output-print (item 1 location)
      ]
  ]
  
end

;---shelter functions---
to attach-shelter-label [x]
  hatch-shelter-labels 1 [
    set which-shelter x
    set size 0
    ask shelters with [who = x] [set ycor ycor - 3]
    set label [num-inside] of shelters with [who = x]
    set label-color black
  ]
end

to increment-in-shelter [ashelter breedo]
  
  ask ashelter 
  [
    set num-inside num-inside + 1
    if member? breedo kids [ set num-kids-ins num-kids-ins + 1]
    if member? breedo teens [ set num-teens-ins num-teens-ins + 1]
    if member? breedo adults [ set num-adults-ins num-adults-ins + 1]
    if member? breedo elders [ set num-elders-ins num-elders-ins + 1]
    
    if(id = 2 and capacity != 500) [ set capacity 500 ]
    if(id = 3 and capacity != 600) [ set capacity 600 ]
    if(id = 4 and capacity != 600) [ set capacity 600 ]
    if(id = 5 and capacity != 80) [ set capacity 80  ]
    if(id = 7 and capacity != 150) [ set capacity 150 ]
    if(id = 8 and capacity != 360) [ set capacity 360 ]
    
  ]
  ;ask shelter-labels with [which-shelter = who] [set label [num-inside] of ashelter]
  
  ask shelter-labels with-min [distance ashelter] [set label (word "[" [capacity] of ashelter "] T:" ([num-inside] of ashelter) 
                                                                   "\n k:" ([num-kids-ins] of ashelter)  
                                                                   "\n t:" ([num-teens-ins] of ashelter)  
                                                                   "\n a:" ([num-adults-ins] of ashelter)  
                                                                   "\n e:" ([num-elders-ins] of ashelter)  
                                                                   
                                                                   ) ]
end

;---exitpoint functions---
to attach-exitpoint-label [x]
  hatch-exitpoint-labels 1 [
    set which-exitpoint x
    set size 0
    ask exitpoints with [who = x] [set ycor ycor - 3]
    set label [num-inside] of exitpoints with [who = x]
    set label-color black
  ]
end

to increment-in-exitpoint [anexit]
  ask anexit [set num-inside num-inside + 1]
  ;ask shelter-labels with [which-shelter = who] [set label [num-inside] of ashelter]
  ask exitpoint-labels with-min [distance anexit] [set label [num-inside] of anexit]
end


to-report new-node-at [x y] ; returns a node at x,y creating one if there isn't one there.
  let n nodes with [xcor = x and ycor = y]
  ifelse any? n [set n one-of n] 
  [
    create-nodes 1 [setxy x y set size 0.5 set n self] 
  ]
  report n
end

to-report new-shelter-at [x y] ; returns a node at x,y creating one if there isn't one there.
  let n shelters with [xcor = x and ycor = y]
  ifelse any? n [set n one-of n] 
  [
    create-shelters 1 [setxy x y set size 6.5 set n self] 
  ]
  report n
end

to-report polylines-of [dataset decimalplaces]
  let polylines gis:feature-list-of dataset                              ;; start with a features list
  set polylines map [first ?] map [gis:vertex-lists-of ?] polylines      ;; convert to virtex lists
  set polylines map [map [gis:location-of ?] ?] polylines                ;; convert to netlogo float coords.
  set polylines remove [] map [remove [] ?] polylines                    ;; remove empty poly-sets .. not visible
  set polylines map [map [map [precision ? decimalplaces] ?] ?] polylines        ;; round to decimalplaces
    ;; note: probably should break polylines with empty coord pairs in the middle of the polyline
  report polylines ;; Note: polylines with a few off-world points simply skip them.
end

to-report session-time 
  ;let $t timer
  let $t (start-ticks + ticks) ;inkremen di sini
  report (word pad($t / 3600) ":"
    pad(($t mod 3600) / 60) ":"
    pad($t mod 60))
end

to-report pad [#number]
  report substring(word (100 + int #number)) 1 3
end

to-report get-start-time-ticks-from-inputs
  report ((jam-mulai * 3600) + (menit-mulai * 60))
end

to drawGIS
  
  ;let scale 5 ; harusnya ada slidernya
  ; 1900x1300 ini resolusi random aja
  let x (1900 / scale) - 1
  let y (-1) * ((1192.5 / scale) - 1)
  resize-world 0 x y 0
  if scale = 5
  [ set-patch-size 2 ]
  if scale = 2
  [ set-patch-size 1 ] ;this is the scale 2mx2m grid
  
  
  gis:set-drawing-color [  181   208   208]    gis:draw Sea 1
    gis:set-drawing-color [  181   208   250]    gis:fill Sea 1
  ;gis:set-drawing-color [  17   114   250]    gis:fill Sea 1
  
  if(fill-gis)
  [
    gis:set-drawing-color [  216   250   212]    gis:draw Land 1
    gis:set-drawing-color [  216   255   202]    gis:fill Land 1
  ]
  
  ;gis:set-drawing-color [0 255 0]    gis:fill Landuse 0
  ;gis:set-drawing-color [  0   0   0]    gis:draw Landuse 1
  
  if(fill-gis)
  [
    ;gis:set-drawing-color [102 204 255]    gis:fill Road 0
    gis:set-drawing-color [  0   0 255]    gis:draw Road 3
  ]
  
  gis:set-drawing-color [230 230 230]    gis:fill Building 0.05
  gis:set-drawing-color [  0   0   0]    gis:draw Building 0.1
  
  ; di sini stretching data gis biar sesuai resolusi dan ga terganggu ukuran patch
  gis:set-world-envelope ( gis:envelope-union-of 
                               (gis:envelope-of Sea)
                               (gis:envelope-of Land)
                               (gis:envelope-of Road)
                               (gis:envelope-of Building)
                         )
  
  
  set sea-patches patches gis:intersecting Sea
  ask sea-patches [set pcolor blue]; sprout 1 [set color violet set size 1 set shape "circle" stamp die]]
  
  set road-patches patches gis:intersecting Road
  ask road-patches [set pcolor green]; sprout 1 [set color violet set size 1 set shape "circle" stamp die]]
  
  set urban-patches patches gis:intersecting Building
  ask urban-patches [set pcolor white];
  
  set adultar-patches patches gis:intersecting AdultAr
  ask adultar-patches [set pcolor white];

  set kidsar-patches patches gis:intersecting KidsAr
  ask kidsar-patches [set pcolor white];
  
  ;gis:set-drawing-color [230 230 230]    gis:fill TEB 0
  ;gis:set-drawing-color [  0   0   0]    gis:draw TEB 1
  
  ;gis:set-drawing-color [255 204 102]    gis:fill TEB 0
  ;gis:set-drawing-color [255 0 0]    gis:draw TEB 2
end

to drawRoad
  foreach gis:feature-list-of Road
  [
    foreach gis:vertex-lists-of ? 
    [
      let previous-turtle nobody
      foreach ? 
      [
        let location gis:location-of ? 
        if not empty? location 
        [
          create-turtles 1
          [set xcor item 0 location
            set ycor item 1 location
            if previous-turtle != nobody 
            [create-link-with previous-turtle]
            set hidden? true
            set previous-turtle self
            ]
        ]
        
      ]
    ]
  ]
end

to placeAgents
  set-default-shape motors "wheel"
  create-motors num-motors[
   setxy random-xcor random-ycor 
   set color brown
  ]
  set-default-shape cars "car"
  create-cars num-cars[
   setxy random-xcor random-ycor 
   set color magenta
  ]
  
end

;human procedures
to load-population
set-default-shape humans "person"

set-default-shape kids "person"
set-default-shape teens "person"
set-default-shape adults "person"
set-default-shape elders "person"

let human-size 1;human-meters/meters-per-patch

;  create-humans num-humans[
;   set speed ((max-human-speed *(1000 / 3600)) / (2.1 * 13)) ; 1px x skala 8000 = 8000px = 2.1 meter; 13 pixel per patch
;   set color yellow
;   let l one-of links
;   set-next-person-link l [end1] of l
;  ]
  
  create-kids num-kids[
   set size 0.6 * 5.0;0.6
   set speed (0.8 * (max-human-speed *(1000 / 3600)) / (2.1 * 13)) ; 1px x skala 8000 = 8000px = 2.1 meter; 13 pixel per patch
   set color yellow
;   let l one-of links
;   if (show-turtle-label)[ set label (word who " [" stage "]") ]
;   set-next-person-link l [end1] of l
  ] 
  
  create-elders num-elders[
   set size 5.0 ;1.0
   set speed (0.7 * (max-human-speed *(1000 / 3600)) / (2.1 * 13))
   set color brown
;   let l one-of links
;   if (show-turtle-label)[ set label (word who " [" stage "]") ]
;   set-next-person-link l [end1] of l
  ] 
  
  create-teens num-teens[
   set size 0.8 * 5.0 ;0.8
   set speed (1.0 * (max-human-speed *(1000 / 3600)) / (2.1 * 13))
   set color orange
;   let l one-of links
;   if (show-turtle-label)[ set label (word who " [" stage "]") ]
;   set-next-person-link l [end1] of l
  ] 
  
  create-adults num-adults[
   set size 5.0 ;1.0
   set speed (1.0 * (max-human-speed *(1000 / 3600)) / (2.1 * 13))
   set color red
;   let l one-of links
;   set-next-person-link l [end1] of l
;   if (show-turtle-label)[ set label (word who " [" stage "]") ]
   set label-color black
  ] 
  
  ;;;let pedestrians (turtle-set kids teens adults elders)
  ; INI UNTUK PENEMPATAN AGEN DI JALAN DAN BANGUNAN
  ;;;ask pedestrians [move-to one-of 
    ;(list one-of urban-patches one-of road-patches)
    ;;;(list one-of urban-patches)
     ;set color black
     ;set size ( 1 / scale * dim ) * scale * 5
     ;;;let s-shapes [ ]
     ;;;let str 0
     ;;;let nd 0
  ;;;]
  
  ifelse(road-only)
  [
    let pedestrians (turtle-set kids teens adults elders)
    ask pedestrians [
      move-to one-of  (list one-of road-patches with [not any? turtles-here])
    ]
;    ask road-patches [
;      if(count kids-here > 1 or count teens-here > 1 or count adults-here > 1 or count elders-here > 1)[
;        print (word count kids-here " " count teens-here " " count adults-here " " count elders-here)
;      ]
;    ]
  ]
  [
   
   let num-adults-placed 0
   ; penempatan agen di area khususnya
   ask adults [
     
     ;ifelse (random 100 <= 40 and use-areas) [ ;40% orang dewasa kerja di laut, sisanya tersebar random di kota, baik yg kerja maupun nganggur digolongkan sama di kota
     ifelse ((random 100 <= 45) and use-areas) [ ; 400 disimpan dulu di area pantai, sisanya baru random di daratan.
       move-to one-of 
       ;(list one-of urban-patches one-of road-patches)
       (list one-of adultar-patches)
     ]
     [
       move-to one-of (list one-of urban-patches)
     ]
      ;set color black
      ;set size ( 1 / scale * dim ) * scale * 5
      let s-shapes [ ]
      let str 0
      let nd 0
   ]  
   
   ask (turtle-set kids teens) [
     ifelse (random 100 <= 80 and use-areas) [ ;80% anak2 beraktivitas di sekitar sekolah, sisanya tersebar di area lain.
       move-to one-of 
       ;(list one-of urban-patches one-of road-patches)
       (list one-of kidsar-patches)
     ]
     [
       move-to one-of 
       (list one-of urban-patches)
     ]
      ;set color black
      ;set size ( 1 / scale * dim ) * scale * 5
      let s-shapes [ ]
      let str 0
      let nd 0
   ] 
   
   ask elders [
      move-to one-of 
      (list one-of urban-patches)     
      ;set color black
      ;set size ( 1 / scale * dim ) * scale * 5
      let s-shapes [ ]
      let str 0
      let nd 0
   ] 
    
  ];end ifelse road-only
  
  
  let pedestrians (turtle-set kids teens adults elders)
    ask pedestrians [
      set td (start-ticks + (random max-delay))
    ]
  
end

to set-next-person-link [l n]
  set cur-link l
  move-to n
  ifelse n = [end1] of l 
   [set to-node [end2] of l]
   [set to-node [end1] of l]
  face to-node
end

to move-human [dist]
  let distoshel distance one-of shelters
  if (distoshel > 0 and distoshel < 1)
  [ set korban-shelter korban-shelter + 1
    ask self [die] ]
  
  let dxnode distance to-node
  ifelse dxnode > dist [forward dist][
     let nextlinks [my-links] of to-node
     ifelse count nextlinks = 1
     [ ifelse (count humans) = 1  
       [ set stopgobutton? true 
         set korban-hilang korban-hilang + 1
         ask self [die] ]
       [ set korban-hilang korban-hilang + 1
         ask self [die] ]
       set-next-person-link cur-link to-node ]
     [ set-next-person-link one-of nextlinks with [self != [cur-link] of myself] to-node]
   move-human dist - dxnode
  ]
end

to move-kid [dist]
  let ashelter one-of shelters
  let distoshel distance ashelter
  if (distoshel > 0 and distoshel < min-safe-distance)
  [ set korban-shelter-kids korban-shelter-kids + 1
    increment-in-shelter ashelter self
    ask self [die] ]
  
  let dxnode distance to-node
  ifelse dxnode > dist [forward dist][
     let nextlinks [my-links] of to-node
     ifelse count nextlinks = 1
     [ ifelse (count humans) = 1  
       [ set stopgobutton? true 
         set korban-hilang-kids korban-hilang-kids + 1
         ask self [die] ]
       [ set korban-hilang-kids korban-hilang-kids + 1
         ask self [die] ]
       set-next-person-link cur-link to-node ]
     [ set-next-person-link one-of nextlinks with [self != [cur-link] of myself] to-node]
   move-human dist - dxnode
  ]
end

to move-teen [dist]
  let ashelter one-of shelters
  let distoshel distance ashelter
  if (distoshel > 0 and distoshel < min-safe-distance)
  [ set korban-shelter-teens korban-shelter-teens + 1
    ;ask ashelter [set num-inside num-inside + 1 set label (word "   " num-inside)]
    increment-in-shelter ashelter self
    ask self [die] ]
  
  let dxnode distance to-node
  ifelse dxnode > dist [forward dist][
     let nextlinks [my-links] of to-node
     ifelse count nextlinks = 1
     [ ifelse (count humans) = 1  
       [ set stopgobutton? true 
         set korban-hilang-teens korban-hilang-teens + 1
         ask self [die] ]
       [ set korban-hilang-teens korban-hilang-teens + 1
         ask self [die] ]
       set-next-person-link cur-link to-node ]
     [ set-next-person-link one-of nextlinks with [self != [cur-link] of myself] to-node]
   move-human dist - dxnode
  ]
end

to move-adult [dist]
  let ashelter one-of shelters
  let distoshel distance ashelter
  if (distoshel > 0 and distoshel < min-safe-distance)
  [ set korban-shelter-adults korban-shelter-adults + 1
    ;ask ashelter [set num-inside num-inside + 1 set label (word "   " num-inside)]
    increment-in-shelter ashelter self
    ask self [die] ]
  
  let dxnode distance to-node
  ifelse dxnode > dist [forward dist][
     let nextlinks [my-links] of to-node
     ifelse count nextlinks = 1
     [ ifelse (count humans) = 1  
       [ set stopgobutton? true 
         set korban-hilang-adults korban-hilang-adults + 1
         ask self [die] ]
       [ set korban-hilang-adults korban-hilang-adults + 1
         ask self [die] ]
       set-next-person-link cur-link to-node ]
     [ set-next-person-link one-of nextlinks with [self != [cur-link] of myself] to-node]
   move-human dist - dxnode
  ]
end

to move-elder [dist]
  let ashelter one-of shelters
  let distoshel distance ashelter
  if (distoshel > 0 and distoshel < min-safe-distance)
  [ set korban-shelter-elders korban-shelter-elders + 1
    ;ask ashelter [set num-inside num-inside + 1 set label (word "   " num-inside)]
    increment-in-shelter ashelter self
    ask self [die] ]
  
  let dxnode distance to-node
  ifelse dxnode > dist [forward dist][
     let nextlinks [my-links] of to-node
     ifelse count nextlinks = 1
     [ ifelse (count humans) = 1  
       [ set stopgobutton? true 
         set korban-hilang-elders korban-hilang-elders + 1
         ask self [die] ]
       [ set korban-hilang-elders korban-hilang-elders + 1
         ask self [die] ]
       set-next-person-link cur-link to-node ]
     [ set-next-person-link one-of nextlinks with [self != [cur-link] of myself] to-node]
   move-human dist - dxnode
  ]
end

;;;;;;;;;;;;;PERGERAKAN;;;;;;;;;;;;;;;;;;

to decide-start
  ; harusnya berdasarkan kurva keputusan mulai pergerakan evakuasi
  if stage = 0 ; and (ticks = (td * 60))
  [ set stage 1 
    if (show-turtle-label)[ set label (word who " [" stage "]") ]
    if breed = kids
     [ set decided-kids decided-kids + 1 ] 
    if breed = teens
     [ set decided-teens decided-teens + 1 ] 
    if breed = adults
     [ set decided-adults decided-adults + 1 ] 
    if breed = elders
     [ set decided-elders decided-elders + 1 ] 
  ]
end

to decide-shelter
  if stage = 1 
  [ 
    ifelse(use-exit)
    [ set goal one-of (turtle-set shelters exitpoints) with-min [distance myself] ]
    [ set goal one-of (turtle-set shelters) with-min [distance myself] ]
    ifelse (breed != cars)
     [ set stage 2 
       if (show-turtle-label)[ set label (word who " [" stage "]") ]
     ]
     [ set stage 4     
       if (show-turtle-label)[ set label (word who " [" stage "]") ]
     ]
  ]
  
end

to decide-road
  if stage = 2
  [ 
    let road1 distance min-one-of road-patches [distance myself]
    let road2 distance min-one-of shelters [distance myself]
    let roado nobody

    ifelse (road1 < road2)
    [
      set roado min-one-of road-patches [distance myself]
      set stage 3 
      if (show-turtle-label)[ set label (word who " [" stage "]") ]
    ]
    [
      set roado min-one-of shelters [distance myself]
      set goal roado
      set stage 5 
      if (show-turtle-label)[ set label (word who " [" stage "]") ]
    ]
  ;  let daroad min-one-of patches with [pcolor = green] [distance myself]
    ; conditions...
 ;   set goal daroad
;    set stage 5
    ;;;;;;;;;
    set path Astar patch-here roado white 4
  ]
end

to follow-path  
  if path = 0 [set path [ ]]
    
  if stage = 3 
  [ ifelse not empty? path
    [ let next first path
      face next
      ;if r.topology?-to-street next
       ;[ 
         fd 1;adjust-speed 
         ;]
      if patch-here = next
       [ set path but-first path ]
    ]
    [ set stage 4 
      if (show-turtle-label)[ set label (word who " [" stage "]") ]
    ]
  ]
  
  if stage = 5
  [ ifelse not empty? path
    [ let next first path
      face next
      ;if r.topology?-on-street next
      ;[ fd speed];adjust-speed ]
      fd 1;speed
      if patch-here = next
      [ set path but-first path ]
      
    ] 
    [ 
      if (patch-here = goal); or (distance goal < min-safe-distance))
      [ if breed = kids [ set korban-shelter-kids korban-shelter-kids + 1]
        if breed = teens [ set korban-shelter-teens korban-shelter-teens + 1]
        if breed = adults [ set korban-shelter-adults korban-shelter-adults + 1]
        if breed = elders [ set korban-shelter-elders korban-shelter-elders + 1]
;        let ashelter min-one-of shelters [distance patch-here]
;        increment-in-shelter ashelter
;        ask self [die]
      ]
    ]
    
  ]
  
end

to search-shelter-route 
  ;set path Astar patch-here goal green 4
  if stage = 4
  [ set path [ ]
    
    if([pcolor] of goal != green)[ set goal min-one-of road-patches [distance one-of shelters] ]
    
    set path Astar patch-here goal green 4
    set Len length path
    set stage 5 
    if (show-turtle-label)[ set label (word who " [" stage "]") ]
    
  ]
  
end

to-report r.topology?-to-street [next]
  ;cek pejalan kaki lain yg ada dalam jarak dan sudut pandang
  let pedestrians (turtle-set 
    other kids in-cone (5 / scale) 60 
    other teens in-cone (5 / scale) 60 
    other adults in-cone (5 / scale) 60 
    other elders in-cone (5 / scale) 60)
  
  ;jika titik yg akan dituju agen tidak kosong dan jumlah agen pejalan kaki di sekitarnya lebih kecil dari 
  ;Cmax-ped yaitu (0.7 x scale ^ 2), yg mewakili kepadatan maksimal di suatu tempat (ruang pribadi agen). dalilnya di mas erick
  ifelse (next != nobody and count pedestrians with [td <= [td] of self and next != patch-here] < Cmax-ped) 
   [ ;set color black ;black artinya kena macetla
     report true ]
   [ ;set color white 
     set color black
     stamp ;white artinya tidak kena macet
     report false ]
end

to decide-road-and-shelter-route [idxrep]
  
  if stage = 2
  [ 
    let nroad min-one-of road-patches [distance myself] ;nearest road
    let road1 distance nroad;jarak ke badan jalan terdekat
    ;print (word "jarak " self " ke jalan: " road1)
    let nshelter min-one-of shelters [distance myself] ;nearest shelter
    
    if(use-exit)
    [ let dexit min-one-of exitpoints [distance myself]
      if(dexit <= nshelter)
      [
        set nshelter dexit
      ]
    ]
    
    let road2 distance nshelter ;jarak ke shelter/exit terdekat
    let roado nobody
    ;komen;print (word "\ndistance " self " to nroad=" road1 ", nshelter=" road2)
    ;tetapkan target terdekat utk A*
    ifelse (road1 < road2) 
    [
      set roado nroad;min-one-of road-patches [distance myself]
      set stage 3 
      if (show-turtle-label)[ set label (word who " [" stage "]") ]
    ]
    [
      set roado nshelter;min-one-of shelters [distance myself]
      set goal roado
      set stage 5 
      if (show-turtle-label)[ set label (word who " [" stage "]") ]
    ]
    
    ;cari path A* berdasarkan target terdekat
    
    ;jika memutuskan tujuan sementara di badan jalan
    if stage = 3 
    [
      ifelse(road1 > 0)
       [ ;komen;print (word "patch sebelum A* offroad: " count patches with [open? = 0] " " count patches with [open? = 1] " " count patches with [open? = 2]) 
         set path Astar patch-here roado white 4       
         ;komen;print (word "patch setelah A* offroad: " count patches with [open? = 0] " " count patches with [open? = 1] " " count patches with [open? = 2])
         
       ]
       [ set path [] ]
     ;;print (word "path awal " who ": " path)
      ;ambil ujung akhir list path seakan agen sudah sampai tujuan sementara
      let firstroadpoint nobody
      ifelse(road1 > 0)
       [ set firstroadpoint last path ]
       [ set firstroadpoint patch-here ]
      
      let lastroadpoint min-one-of road-patches [distance nshelter] ;tetapkan tujuan sementara kedua yaitu titik jalan yg terdekat dgn shelter terdekat
      ;komen;print (word "firstroad: " who ": " firstroadpoint " [" [pcolor] of firstroadpoint "] lastroad: " lastroadpoint " [" [pcolor] of firstroadpoint "]")
      ask firstroadpoint [ set open? 1]
;      print (word "patch jalan yg open: " count road-patches with [open? = 1])
      ;komen;print (word "patch sebelum A* onroad: " count patches with [open? = 0] " " count patches with [open? = 1] " " count patches with [open? = 2]) 
      let path-on-road Astar firstroadpoint lastroadpoint green 4 ;mulai pencarian path dengan A*
      ;komen;print (word "patch setelah A* onroad: " count patches with [open? = 0] " " count patches with [open? = 1] " " count patches with [open? = 2]) 
            ;komen;print (word "path onroad " who ": " path-on-road)      
        ;begin rekalkulasi
        ;coba "dijalani" dulu tiap2 path, kalo ada elemen path yg jika agen ada di sana ternyata nemu shelter/exit yg lebih dekat dari tujuan akhirnya, maka ganti goal dgn temuan baru tsb.
        ;siapkan shelter/exit yg bukan shelter/exit yg ditetapkan sbg tujuan akhir agen di awal
        ;set path-on-road (redefine-goal path-on-road)
      ;;if(not empty? path-on-road) [
        ;;set lastroadpoint last path-on-road
        ;end rekalkulasi
        
        set path (sentence path path-on-road) ;konkatenasi list hasil A* terbaru dengan yg lama
        let path-off-road-to-goal Astar lastroadpoint goal white 4
            ;komen;print (word "path offroad " who ": " path-off-road-to-goal)
        set path (sentence path path-off-road-to-goal) ;konkatenasi list hasil A* terbaru dengan yg lama
      ;;]
      set Len length path
      
    ]
    ; memutuskan langsung ke shelter tanpa lewat jalan
    if stage = 5 
    [ set path Astar patch-here roado white 4
      set Len length path
    ]
    ;komen;print (word "path akhir " who ": " path)
    
    set agent-done-astar agent-done-astar + 1
    clear-output
    if(rep-gen)[ output-print (word "repetisi ke-" idxrep) ]
    output-print (word "agen beres A* : " agent-done-astar " dari " (num-kids + num-teens + num-adults + num-elders ) "\n")

    if (agent-done-astar >= (num-kids + num-teens + num-adults + num-elders ))
    [
      if (save-file?)[
       ifelse (save-file-name = "")
        [export-world (word "autosave-bkl-sim-export_" date-and-time ".csv")]
        [ 
          ifelse(rep-gen)
          [ export-world (word save-file-name "-" idxrep ".csv") ]
          [ export-world (word save-file-name ".csv") ]
          
         ]
      ]
      
      if(rep-gen)[ set agent-done-astar 0 ]
          
    ]
  ]
  
end

to-report redefine-goal [roadpath]
  
  if(empty? roadpath) [ report [ ] ]
  
  let initial-pos first roadpath
  let initial-goal last roadpath
  let otherend nobody
  
  ask initial-goal [ set otherend other (turtle-set shelters exitpoints) ]
  
  let dist1 0
  let dist2 0
  let min-otherend nobody
  
  foreach roadpath
  [
    ask ? [
      set dist1 distance initial-goal
      set min-otherend min-one-of otherend [distance myself]
      set dist2 distance min-otherend
      
      
    ]
    
    ifelse(dist2 < dist1 and min-otherend != goal)
    [ 
      print (word "agent " who " change goal from " goal " to " min-otherend)
      let newgoal min-otherend
      let lastroadpoint min-one-of road-patches [distance newgoal]
      
      set goal newgoal
      
      report Astar initial-pos lastroadpoint green 4
    ]
    [

    ]
    
  ]
  report Astar initial-pos initial-goal green 4
  
end

to follow-predefined-path 
  ;print (word ( ticks) " " (60 * td))
  if (ticks >= (td * 60)) [ ;jika td masuk tick, baru mulai jalan
    ;follow the path
    if stage = 3 or stage = 5 ;baik sudah maupun belum di badan jalan, tetap bergerak
    [ ifelse not empty? path
      [ let next first path
        face next
        if r.topology?-to-street next
        [ 
           fd adjust-speed
        ]
        if patch-here = next
         [ 
           if(pragmagent) [
             ;pengguncangan keteguhan, mulai.
             let curpath first path
             set backupath lput curpath backupath
             ask curpath [
               let goalinrange min-one-of shelters in-radius 10 [distance-nowrap self] 
               
               if (goalinrange != nobody)[ ;and
                 ifelse(goalinrange != [goal] of myself) [
                   
                  ifelse([num-inside] of goalinrange < [capacity] of goalinrange) 
                  [ 
                    print (word myself " on " self " oldgoal: " [goal] of myself " goalinrange: " goalinrange) 
                    print (word "old path: " [path] of myself )
                     
                    let newpath Astar curpath goalinrange white 4
                    ask myself [ 
                      set goal goalinrange 
                      set path newpath 
                      set backupath (sentence backupath newpath)
                    ]
                    print (word "new path: " [path] of myself )
                  ]
                  [ 
                    let lowonggoal min-one-of (shelters with [ num-inside < capacity ]) [distance-nowrap self] 
                    
                    if(lowonggoal != nobody and lowonggoal != [goal] of myself and 
                      distance lowonggoal < distance [goal] of myself) [
                      
                        let logoalroad min-one-of road-patches [distance lowonggoal]
                        print (word "\n" myself " on " self " oldgoal: " [goal] of myself ", mau ke " goalinrange " penuh!, jadinya ke: " lowonggoal) 
                        
                        let newpathroad Astar curpath logoalroad green 4
                        let newoffroadpath Astar logoalroad lowonggoal white 4
                        
                        ask myself [ 
                           let joinedpath (sentence newpathroad newoffroadpath)
                           set goal lowonggoal 
                           set path joinedpath
                           set backupath (sentence backupath joinedpath)
                         ]
                        
                        print (word "new path gara2 penuh: " [path] of myself )
                     ]
                  ];end IF belum overflow
                 
               ]
               [
                 if([num-inside] of goalinrange >= [capacity] of goalinrange) [ 
                   let lowonggoal min-one-of (shelters with [ num-inside < capacity ]) [distance-nowrap myself] 
                   
                   if(lowonggoal != nobody and lowonggoal != [goal] of myself) [
                     
                       let logoalroad min-one-of road-patches [distance lowonggoal]
                       print (word "\n" myself " on " self " oldgoal: " [goal] of myself ", mau ke " goalinrange " penuh!!!, jadinya ke: " lowonggoal) 
                       
                       let newpathroad Astar curpath logoalroad green 4
                       let newoffroadpath Astar logoalroad lowonggoal white 4
                       
                       ask myself [ 
                          set goal lowonggoal 
                          set path (sentence newpathroad newoffroadpath)
                        ]
                       
                       print (word "new path gara2 penuh: " [path] of myself )
                    ]
                 ];end IF belum overflow
               ]  
                 
              ]
                 
             ];end ask curpath
           ];end IF pragmagent
           ;pengguncangan keteguhan, selesai.
           
           set path but-first path 
         ]
      ]
      [ ]
      ;[ set stage 4 set label (word who " [" stage "]")]
    ]
  ];end if td
end

to-report adjust-speed
  let s 0
  
  ifelse breed != cars
  [ let pedestrians (turtle-set 
    other kids in-cone (5 * 2 / scale) 60 
    other teens in-cone (5 * 2 / scale) 60 
    other adults in-cone (5 * 2 / scale) 60 
    other elders in-cone (5 * 2 / scale) 60)
  
  let p count pedestrians; with [td > [td] of self] ;hitung jumlah pejalan kaki yg berangkat belakangan
  ;print (word "p of " who ": " pedestrians)
  let a ((3 * pi / 4 ) * 5 ^ 2) / 2 ;ini belum paham maksudnya apa
  let d p / a ;
  set s precision ((1 / SQRT(2 * pi * 0.3 ^ 2)) * EXP(- ((d -  0) ^ 2) / (2 * 0.3 ^ 2))) 2
    
  ]
  [
    ;untuk handle car, belum
    ]
  ;let world-envelope gis:world-envelope
    
    ;let gis-width 1351 ;(item 1 world-envelope - item 0 world-envelope) 
    ;let gis-height 835 ;(item 3 world-envelope - item 2 world-envelope) 
    
    ;let factor max list (gis-width / world-width) 
    ;                   (gis-height / world-height)
                       
  ;print (word "s of " who ": " s)
  set s s / (scale)
  ;print (word "s of " who ": " (s * factor))
  report s
  
end

;;*******************************************************************
;; A star searched by patches
;; Developed by E. Mas
;; October 2011
;; modified June 2012
;; revised July 2012
;;*******************************************************************
to-report Astar [setup-start setup-goal setup-color behavior]
  set start setup-start
  set target setup-goal
  set space-color setup-color
  set heuristic list behavior behavior
  
  ask patches with [open? != 0]
  [ set f 0 set g 0 set h 0 set parent nobody set open? 0]
  ask target [set pcolor space-color]
  ;1) Begin at the starting point A and
  ;add it to an open list of squares to be considered.
  ;The open list is kind of like a shopping list.
  ;Right now there is just one item on the list,
  ;but we will have more later.
  ;It contains squares that might fall along the path you want to take,
  ;but maybe not. ;Basically, this is a list of squares that need to be checked out.
  
  ask start [set open? 1 set parent self 
    if space-color = green and pcolor != green [ set pcolor green ]]
  ;komen;print (word "Astarring: " who " " space-color " start: [" start " open? " [open?] of start "] ")
  while [ [open?] of target != 2 ]
  [
    if count patches with [open? = 1] = 0 and [open?] of start != 1 [print(word "yg open kosong! start open? " [open?] of start) report [ ]]
    
    ;choose the lowest F score square from all those that are
    ;on the open list.
    let open-agentset patches with [open? = 1]
    ask open-agentset [ fgh-values ]
    let current one-of open-agentset with-min [f]
    
    ;4) Drop it from the open list and add it to the closed list
    ask current [set open? 2] ;sprout 1  [ set shape "bot" set color red stamp die]
    ;display
    
    ;5) Check all of the adjacent squares.
    ;Ignoring those that are on the closed list or unwalkable
    ;(terrain with walls, water, or other illegal terrain),
    ;add squares to the open list
    ;if they are not on the open list already.
    ;Make the selected square the parent of the new square
    
    let walkable [neighbors with [pcolor = space-color]] of current
    ;if count walkable = 0 [report [ ]]
    ask walkable [ if open? != 2 ;not closed
                   [ ifelse open? != 1; not open
                     [ set open? 1
                       set parent current
                     ]
                     
                     
    ;6) If an adjacent square is already on the open list,
    ;check to see if this path to that square is a better one.
    ;In other words, check to see if the G score for that square is lower
    ;if we use the current square to get there. If not, dont do anything.
    ;On the other hand, if the G cost of the new path is lower,
    ;change the parent of the adjacent square to the selected square
    ;Finally, recalculate both the F and G scores of that square.
    ;If this seems confusing, you will see it illustrated below.
    
                    [ let previous-parent parent
                      ifelse path-cost self > new-path-cost current self
                      [ set parent current fgh-values ]
                      [ set parent previous-parent fgh-values ]
                    ]
                   ]
                 ]  
  ];endwhile
  
  ;ask target [sprout 1 [set size 20 set shape "dot" set color pink stamp die]]
  ;ask target [set pcolor targetorigcol]
  
  report show-path
  
end


to fgh-values
  set g precision distance-nowrap parent 2
  set h precision #heuristic 2
  set f path-cost self + h
end

to-report path-cost [candidate]
  let cost 0
  let brush candidate
  ask brush [ set cost (cost + g)]
  while [brush != start]
  [ ask [parent] of brush [set cost (cost + g)]
    set brush [parent] of brush
  ]
  report cost
end

to-report new-path-cost [ current candidate ]
  ask candidate [ set parent current fgh-values ]
  let cost path-cost candidate
  report cost
end

to-report show-path
  let brush target
  let my-path [ ]
  set my-path fput brush my-path
  while [brush != start]
  [ set my-path fput ([parent] of brush) my-path
    set brush [parent] of brush
    ;ask brush [set pcolor pink] untuk debug path
  ]
  report my-path
end

to-report #heuristic 
  if first heuristic = -1
  [ report 0 ]
  
  if first heuristic = 0
  [ report precision distance-nowrap target 2 ]
  
  if first heuristic = 1
  [ let xdiff abs(pxcor - [pxcor] of target)
    let ydiff abs(pycor - [pycor] of target)
    let result (xdiff + ydiff)
    report result
  ]
  
  if first heuristic = 2
  [ let D 1
    let D2 1.414214
    let xdiff abs(pxcor - [pxcor] of target)
    let ydiff abs(pycor - [pycor] of target)
    let h_diagonal min (list xdiff ydiff)
    let h_straight xdiff + ydiff
    let result D2 * h_diagonal + D * (h_straight - 2 * h_diagonal)
    report result  
  ]
  
  if first heuristic = 3
  [ let D 1
    let D2 1.414214
    let xdiff abs(pxcor - [pxcor] of target)
    let ydiff abs(pycor - [pycor] of target)
    let h_diagonal min (list xdiff ydiff)
    let h_straight xdiff + ydiff
    let result D2 * h_diagonal + D * (h_straight - 2 * h_diagonal)
    
    ;; tie-breaker: nudge H up by a small amount ; bagian ini ga paham
    let h-scale (1 + (16 / 8 / world-width + world-height))
    set result result * h-scale

    report result  
  ]
  
  if first heuristic = 4
  [ let result distance-nowrap target
    let h-scale (1 + (16 / 8 / world-width + world-height)) ;aslinya width tambah height, tapi mencurigakan, yaudah ganti jadi * aja
    set result result * h-scale
    report result
  ]
  
end
@#$#@#$#@
GRAPHICS-WINDOW
286
55
1056
562
-1
-1
2.0
1
10
1
1
1
0
0
0
1
0
379
-237
0
1
1
1
ticks
30.0

BUTTON
32
529
95
562
setup
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

BUTTON
108
529
171
562
go
go
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
4
163
119
196
num-motors
num-motors
0
1000
69
1
1
NIL
HORIZONTAL

SLIDER
5
124
118
157
num-cars
num-cars
0
1000
80
1
1
NIL
HORIZONTAL

BUTTON
180
529
243
562
NIL
go
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
917
633
1029
666
node-precision
node-precision
0
6
6
1
1
NIL
HORIZONTAL

MONITOR
1184
620
1246
665
Nodes
count nodes
17
1
11

MONITOR
1250
620
1309
665
Links
count links
17
1
11

MONITOR
1172
10
1291
55
Jumlah terevakuasi
korban-shelter
17
1
11

MONITOR
1056
10
1157
55
waktu terkini
session-time
17
1
11

INPUTBOX
124
126
185
186
jam-mulai
7
1
0
Number

INPUTBOX
186
126
254
186
menit-mulai
45
1
0
Number

SLIDER
9
85
155
118
max-human-speed
max-human-speed
1
20
5
1
1
km/h
HORIZONTAL

PLOT
1056
59
1292
205
jumlah korban terevakuasi
waktu
jumlah korban
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"total" 1.0 0 -13345367 true "" "plot korban-shelter"
"anak" 1.0 0 -1184463 true "" "plot korban-shelter-kids"
"remaja" 1.0 0 -955883 true "" "plot korban-shelter-teens"
"dewasa" 1.0 0 -2674135 true "" "plot korban-shelter-adults"
"tua" 1.0 0 -6459832 true "" "plot korban-shelter-elders"

OUTPUT
1056
205
1307
561
10

SLIDER
3
196
97
229
num-shelters
num-shelters
1
8
8
1
1
NIL
HORIZONTAL

SLIDER
8
14
109
47
num-kids
num-kids
0
10000
608
1
1
NIL
HORIZONTAL

SLIDER
8
49
109
82
num-teens
num-teens
0
10000
125
1
1
NIL
HORIZONTAL

SLIDER
113
15
219
48
num-adults
num-adults
0
10000
878
1
1
NIL
HORIZONTAL

SLIDER
113
50
220
83
num-elders
num-elders
0
10000
42
1
1
NIL
HORIZONTAL

SWITCH
1031
633
1180
666
show-turtle-label
show-turtle-label
1
1
-1000

SWITCH
8
440
113
473
load-file?
load-file?
1
1
-1000

INPUTBOX
118
400
256
460
save-file-name
bkl-sim-6shelter-allroad-fix-10
1
0
String

SWITCH
6
400
115
433
save-file?
save-file?
0
1
-1000

SWITCH
186
195
280
228
road-only
road-only
1
1
-1000

SWITCH
36
263
126
296
shltr-1
shltr-1
1
1
-1000

SWITCH
125
263
215
296
shltr-2
shltr-2
0
1
-1000

SWITCH
36
297
126
330
shltr-3
shltr-3
0
1
-1000

SWITCH
125
297
215
330
shltr-4
shltr-4
0
1
-1000

SWITCH
35
331
125
364
shltr-5
shltr-5
0
1
-1000

SWITCH
125
331
215
364
shltr-6
shltr-6
1
1
-1000

SWITCH
35
364
125
397
shltr-7
shltr-7
0
1
-1000

SWITCH
125
364
215
397
shltr-8
shltr-8
0
1
-1000

SWITCH
98
195
188
228
use-exit
use-exit
1
1
-1000

SLIDER
156
85
248
118
max-delay
max-delay
0
15
5
1
1
NIL
HORIZONTAL

SWITCH
99
229
215
262
gov-road-only
gov-road-only
1
1
-1000

SWITCH
285
16
440
49
pathfind-on-setup
pathfind-on-setup
0
1
-1000

SWITCH
438
16
528
49
fill-gis
fill-gis
0
1
-1000

SWITCH
528
16
638
49
use-areas
use-areas
0
1
-1000

INPUTBOX
115
463
165
523
idx-awal
1
1
0
Number

INPUTBOX
166
463
216
523
idx-akhir
10
1
0
Number

SWITCH
23
477
113
510
rep-gen
rep-gen
0
1
-1000

SWITCH
795
19
918
52
pragmagent
pragmagent
0
1
-1000

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
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
NetLogo 5.0.4
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 1.0 0.0
0.0 1 1.0 0.0
0.2 0 1.0 0.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

@#$#@#$#@
0
@#$#@#$#@
