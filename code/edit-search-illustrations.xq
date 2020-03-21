let $serialize := util:declare-option("exist:serialize","method=xhtml media-type=text/html")
let $species-list := doc("illustrations.xml")/species-list
let $latin := request:get-parameter("latin",())
let $mode := request:get-parameter("mode","form")

let $wikicommons := concat("https://commons.wikimedia.org/w/index.php?title=Special:Search&amp;limit=500&amp;offset=0&amp;search=",replace($latin," ","_"))
let $images := for $table in doc($wikicommons)//table[@class="searchResultImage"]
               return 
                  element illustration {
                     element thumb {$table//img/@src/string()},
                     element url {concat("https://commons.wikimedia.org",$table//td[1]/a/@href/string())},
                     element text {$table//td[2]/div[1]/string()}
                  }
let $species  := $species-list/species[latin=$latin]
return
if ($mode="debug")
then <div>{$images}</div>
else if ($mode="form")
then 
let $form :=
   <form action="?" method="post">
   <input type="hidden" name="latin" value="{$latin}"/>
   
   <table>
    <tr><td><input type="submit" name="mode" value="save"/></td></tr>
      {for $image at $i in $images
       let $caption := $species/illustration[url=$image/url]/caption
       order by $caption
       return 
       <tr><td><a href="{$image/url}"><img src="{$image/thumb}" width="150"/></a></td>
           <td width="40%">{$image/text/string()}</td>
           <td><input type="text" name="image-{$i}" size="20" value="{$caption}"/></td>
       </tr>
      }
      <tr><td><input type="submit" name="mode" value="save"/></td></tr>
      </table>
    </form>
return
   <div>
     <h3>{$latin}</h3>
     {$form}
   </div>
else if ($mode="save")
then let $illustrations := 
                      for $param in request:get-parameter-names()
                      let $param-p := tokenize($param,"-")
                      let $index := number($param-p[2])
                      let $value := request:get-parameter($param,())
                      where $param-p[1] = "image" and $value !=""
                      return
                         let $image := $images[$index]
                         let $imagedoc := doc($image/url)
                         let $imageurl := $imagedoc//div[@class="fullImageLink"]//img/@src/string()
                         return
                         element illustration {
                             $image/*,
                             element imageurl {$imageurl},
                             element caption {$value}
                         }
     let $new-species := 
          element species {
                 element latin {$latin},
                 $illustrations
          }
     let $update :=
         if ($species)
         then update replace $species with $new-species
         else update insert $new-species into $species-list
     return
        <div>{$latin} updated : <a href="guide.xq">Index</a> &#160; <a href="guide.xq?latin={$latin}">View</a> &#160; <a href="?latin={$latin}">Redit</a></div>

else ()
