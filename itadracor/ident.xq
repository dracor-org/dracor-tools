xquery version "3.1";

import module namespace functx="http://www.functx.com";
declare namespace tei = "http://www.tei-c.org/ns/1.0";

declare function local:filter-speaker($s as element()) as xs:string {
  normalize-space(functx:remove-elements-deep($s, '*:note'))
};

declare function local:normalize($s as xs:string) as xs:string {
  normalize-space(lower-case(replace($s, '[\[\]{}<>.;,:]', '')))
};

declare function local:capitalize($s as xs:string) as xs:string {
  if (matches($s, '\p{Lu}', '') and matches($s, '\p{Ll}', '')) then
    $s
  else
    let $tokens := tokenize($s, '\s')
    let $words := for $t in $tokens
      return concat(upper-case(substring($t,1,1)), lower-case(substring($t, 2)))
    return string-join($words, ' ')
};

let $col := collection('/db/data/dracor/tei/ita')

return <plays>
{
  for $tei in $col//tei:TEI
  let $idno := $tei//tei:idno[@type="dracor"]/text()
  let $speaker-texts := for $s in $tei//tei:speaker return local:filter-speaker($s)
  let $speakers := for $speaker in $speaker-texts return
    for $t in tokenize($speaker, '( e &apos;l |\W[eE][dD]?\W|, +)')
    return local:normalize($t)
  let $has-cast := if (count($tei//tei:castItem)) then true() else false()
  return
  <play id="{$idno}" title="{$tei//tei:titleStmt/normalize-space()}">
    <cast>
    {
      for $item in $tei//tei:castList/tei:castItem
      let $role := $item/tei:role/normalize-space()
      return
      <item role="{$role}" n="{count($role)}" x="{local:normalize($role[1])}">
      {normalize-space($item)}
      </item>
    }
    </cast>
    <speakers>
      {
        for $spk in distinct-values($speakers)
        let $matches := $tei//tei:castItem/tei:role[local:normalize(.) = $spk or starts-with(replace(local:normalize(.), "^(il |la |l')", ''), $spk)]
        return
        <s n="{count($matches)}">
          {
            if (count($matches) = 1) then
              attribute {'label'}{local:capitalize($matches[1])}
            else ()
          }
          {
            if (not($has-cast)) then
              attribute {'label'}{local:capitalize($spk)}
            else ()
          }
          {$spk}
        </s>
      }
    </speakers>
  </play>
}
</plays>


  (: <texts>
    {
      for $spk in distinct-values($speaker-texts)
      order by $spk
      return <speaker>{$spk}</speaker>
    }
  </texts> :)
