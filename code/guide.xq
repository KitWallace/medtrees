declare namespace mt ="http://kitwallace.co.uk/mt";

declare variable $mt:epithets := doc("epithets.xml");

declare function mt:parse-latin($latin) {
    if ($latin = "" or $latin = "Unknown species")
    then ()
    else if (contains($latin," x "))
    then mt:parse-cross($latin)
    else mt:parse-noncross($latin)
};

declare function mt:parse-noncross($s) {
  let $parts := tokenize($s," ")
  let $genus := element genus {$parts[1]}
  let $species := if ($parts[2] and not (starts-with($parts[2],"'")))
                  then element species {$parts[2]}
                  else ()
  let $rest := if ($species)
               then string-join(subsequence($parts,3)," ")
               else string-join(subsequence($parts,2)," ")
  let $form := if (starts-with($rest,"f."))
               then element form {normalize-space(substring-after($rest,"f."))}
               else ()
 let $subspecies := if (starts-with($rest,"subsp."))
               then let $srest := normalize-space(substring-after($rest,"subsp."))
                    return
                        if (ends-with($srest,"'"))
                        then let $subsp:= normalize-space(substring-before($srest,"'"))
                             return element subspecies {$subsp}
                        else element subspecies {$srest}
               else ()
 let $variety := if (starts-with($rest,"var."))
                  then element variety {normalize-space(tokenize($rest, " ")[2])}
                  else if (starts-with($rest,"var "))
                  then element variety {normalize-space(tokenize($rest, " ")[2])}
                  else ()
                  
  let $cultivar := if (starts-with($rest,"'"))
                   then element cultivar {substring($rest,2,string-length($rest)-2)}
                   else if ($rest = ("cv","cultivar"))
                   then element cultivar {}
                   else if ($variety)
                   then let $crest := normalize-space(substring-after($rest,$variety))
                        return
                          if (starts-with($crest,"'"))
                          then element cultivar {substring($crest,2,string-length($crest)-2)}
                          else  ()
                   else if ($subspecies)
                   then let $crest := normalize-space(substring-after($rest,$subspecies))
                        return
                          if (starts-with($crest,"'"))
                          then element cultivar {substring($crest,2,string-length($crest)-2)}
                          else  ()
                   else ()
 let $group := if (ends-with($rest,"Group"))
               then element group {normalize-space(substring-before($rest,"Group"))}
               else if (ends-with($rest,"group"))
               then element group {normalize-space(substring-before($rest,"group"))}
               else ()  
  return
     element latin {
        $genus,
        $species,
        $form,
        $variety,
        $subspecies,
        $cultivar,
        $group
     }     
};

declare function mt:parse-cross($s){
    let $parts := tokenize($s," x ")
    let $sparts := tokenize($parts[1]," ")
    let $genus := element genus {$sparts[1]}
    let $species := if ($sparts[2]) then element species {$sparts[2]} else ()
    let $cross-name := if (contains($parts[2],"'")) then substring-before($parts[2], " '") else $parts[2]
    let $cross := element cross {if ($cross-name != "") then $cross-name else "?"}
    let $rest := if (contains($parts[2],"'")) then substring-after($parts[2],"'") else ""
    let $cultivar := if ($rest != "") then element cultivar {substring($rest,1,string-length($rest)-1)} else ()
    return
       element latin {
         $genus,
         $species,
         $cross,
         $cultivar
      }
};

declare function mt:extend-parse($parse) {
let $genus := $mt:epithets//genus[name=$parse/genus]
return
  element latin {
     element genus {$genus/(* except species)},
     element species {
         element name {$parse/species/string()},
         ($genus/species[name=$parse/species]/meaning,$mt:epithets//species[name=$parse/species]/meaning)[1],
         ($genus/species[name=$parse/species]/pronunciation,$mt:epithets//species[name=$parse/species]/pronunciation)[1]
     },
     $mt:epithets//cultivar[name=$parse/cultivar],
     element cross {($mt:epithets//cross[name=$parse/cross]/node(),$mt:epithets//*[name=$parse/cross]/node())[1]},
     $mt:epithets//variety[name=$parse/variety],
     $mt:epithets//form[name=$parse/form],
     if ($mt:epithets//*[name=$parse/subspecies])
     then element subspecies {$mt:epithets//*[name=$parse/subspecies]/node()}
     else ()
     }
};

declare function mt:illustrations-list () {
    doc("illustrations.xml")//species  
};
declare function mt:illustrations($latin) {
     doc("illustrations.xml")//species[latin=$latin]/illustration
};

declare function mt:species-list() {
     doc("mymedlist.xml")//species
};

declare function mt:species($latin) {
     doc("mymedlist.xml")//species[latin=$latin]
};

declare function mt:species-page($species,$linked,$edit) {
   let $latin := $species/latin[1]
   let $latin-parse := mt:parse-latin($latin)
   let $latin-extend := mt:extend-parse($latin-parse)
   let $illustrations := mt:illustrations($species/latin)
   return
    <div>
    <div class="caption"><em>{$latin}</em> &#160;{string-join($species/common,", ")}</div>
    {if (count($species/latin)>1)
     then  <div class="entry">Synonyms &#160;<em>{string-join(subsequence ($species/latin,2),", ")} </em></div>
    else ()
    }
    
    <div class="entry">Family  <em> {$species/family}</em> </div>
    <div class="entry">Genus <em>{$latin-parse/genus}</em> &#160;{if ($latin-extend/genus/pronunciation != "") then concat("[",$latin-extend/genus/pronunciation/string(),"]")else ()} 
       &#160;{$latin-extend/genus/meaning/string()}</div>
    <div class="entry">Species <em>{$latin-parse/species}</em>&#160; {if ($latin-extend/species/pronunciation != "") then concat("[",$latin-extend/species/pronunciation/string(),"]")else ()} 
       &#160;{$latin-extend/species/meaning/string()}</div>
     
    {if ($species/tag) 
      then 
      <div class="entry">Properties 
      {if($linked)
           then <span> {for $tag in $species/tag return <a href="?mode=list&amp;tag={$tag}">{$tag}</a> } </span> 
           else <span> {string-join($species/tag,", ")}</span> 
      }
      </div>
      else ()
    }

    <div class="entry">{$species/abstract/node()}</div>
    
    {if($linked)
    then <div class="entry">Links: <a href="https://en.wikipedia.org/wiki/{replace($latin," ","_")}">Wikipedia</a>  &#160;
    <a href="http://dbpedia.org/page/{replace($latin," ","_")}">dbpedia</a> &#160;
    <a href="https://commons.wikimedia.org/wiki/{replace($latin," ","_")}">Wikimedia Commons</a> &#160;
    <a href="http://bristoltrees.space/Tree/species/{$latin}">Bristol Trees</a>&#160;
    <a href="https://www.pfaf.org/user/Plant.aspx?LatinName={$latin}">PFAF</a>&#160;
    <a href="https://www.google.co.uk/search?q={$latin} ">Search</a> &#160;
    <a href="https://www.google.co.uk/search?q={$latin} distribution ">Distribution</a> &#160;
   
     
     </div>
     else ()
     }
     <div class="entry"> 
      {if ($edit)
       then <span>
              <a href="edit-illustrations.xq?latin={$latin}">Edit from Category</a>&#160;
              <a href="edit-search-illustrations.xq?latin={$latin}">Edit from Search</a>
            
            </span>
       else ()
       }
   {for $illustration in $illustrations

    return <div>
                 <div class="caption">{ $illustration/caption/string()}</div>
                 <a href="{$illustration/url}"><img src="{ $illustration/imageurl}" width="600"/></a> 
                 
           </div>
   }
   </div>
   </div>
};

let $serialize := util:declare-option("exist:serialize","method=xhtml media-type=text/html")
let $latin := request:get-parameter("latin",())
let $mode := request:get-parameter("mode","list")
let $edit := true()  (: (request:get-parameter("p",())="q")  :)
let $tag := request:get-parameter("tag",())
return 
  <html>
   <head>
       <link rel="stylesheet" type="text/css"
            href="https://fonts.googleapis.com/css?family=Merriweather Sans"/>
       <link rel="stylesheet" type="text/css"
            href="https://fonts.googleapis.com/css?family=Gentium Book Basic"/>
       <meta name="viewport" contents="width=device-width, initial-scale=1.0"/>
       <script type="text/javascript" src="sorttable.js"></script> 
       <link rel="stylesheet" type="text/css" media="screen" href="base.css"  />
       <link rel="stylesheet" type="text/css" media="only screen and (max-device-width: 480px)" href="base-phone.css"  />

   </head>
   <body>
   <div>
   <div class="caption">Book of Mediterranean Trees, Shrubs and Climbers</div>
{
if ($mode ="list" and $latin) 
then 
   let $species := mt:species($latin)
   return
       <div>  <h3><a href="?">Index</a></h3>
          {mt:species-page($species,true(),$edit)}
        </div>
else if ($mode = "list")
then 
  let $species-list := mt:species-list()
  let $illustrated-species :=  mt:illustrations-list ()
  let $n-species := count($species-list)
  let $n-illustrated := count($illustrated-species)
  return
 <div>
 <h3> {$n-species} Species, {$n-illustrated} Illustrated, {round($n-illustrated * 100 div  $n-species)}%.
   <a href="?mode=book">Book</a>
 </h3>
  <table class="sortable">
  <tr><th>Latin</th><th>Common</th><th>Family</th><th>tags</th><th>Illustrated</th></tr>
   {
    for $species in  (if ($tag) then $species-list[tag=$tag] else $species-list)
    let $illustrated := if (mt:illustrations($species/latin)) then 1 else 0
    order by $species/latin[1]
    return
    <tr>
    <td><a href="?latin={$species/latin[1]}">{$species/latin[1]}</a></td>
   
    <td>{string-join($species/common,", ")}</td>
    <td>{$species/family}</td>
    <td>{string-join($species/tag,", ")}</td>
    <td>{if ($illustrated) then "+" else ()}</td>
  
    </tr>
   } 
  </table>
  </div>
else if ($mode="book")
then 
  <div>
    <table id="index" width="100%">
    <tr><th>Latin</th><th>Common</th></tr>
   {let $species-list := mt:species-list()
    for $species in  (if ($tag) then $species-list[tag=$tag] else $species-list)
    order by $species/latin[1]
    return
    <tr>
    <td><a href="#{$species/latin[1]}">{$species/latin[1]}</a> 
    {if (mt:illustrations($species/latin)) then " + " else () }
     </td>
   
    <td>{string-join($species/common,", ")}</td>
    </tr>
   } 
  </table>
     {for $species in mt:species-list()
      
      return
        <div id="{$species/latin[1]}">
           {mt:species-page($species,false(),false())}
           <a href="#index">Index</a>
           <hr size="5"/>
        </div>
     }
  </div>
else if ($mode="captions")
then 
element captions {
      for $caption in distinct-values( mt:illustrations-list () //caption )
      order by $caption
      return element caption {attribute order {},$caption}
      }
else ()
}
</div>
</body>
</html>
