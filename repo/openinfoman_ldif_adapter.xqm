(:~
: This is the Care Services Discovery stored query registry
: @version 1.0
: @see https://github.com/openhie/openinfoman
:
:)
module namespace ldif = "https://github.com/openhie/openinfoman/adapter/ldif";

import module namespace oi_csv = "https://github.com/openhie/openinfoman/adapter/csv";
import module namespace csd_dm = "https://github.com/openhie/openinfoman/csd_dm";
import module namespace csr_proc = "https://github.com/openhie/openinfoman/csr_proc";
import module namespace proc = "http://basex.org/modules/proc ";
import module namespace file = "http://expath.org/ns/file";
import module namespace csd_webconf =  "https://github.com/openhie/openinfoman/csd_webconf";
import module namespace functx = "http://www.functx.com";

declare namespace csd = "urn:ihe:iti:csd:2013";



declare function ldif:is_ldif_function($ldif_name) {
  let $function := csr_proc:get_function_definition($csd_webconf:db,$ldif_name)
  let $adapter := $function//csd:extension[ @type='ldif' and @urn='urn:openhie.org:openinfoman:adapter']
  return $adapter
};



declare function ldif:get($csd_doc,$careServicesRequest) 
{
  ldif:get($csd_doc,$careServicesRequest,map:new(()))
};


declare function ldif:get($csd_doc,$careServicesRequest,$processors as map(xs:string, function(*))) 
{
  let $ldif_name := string($careServicesRequest/@function)
  let $doc_name := string($careServicesRequest/@resource)
  let $function := csr_proc:get_function_definition($csd_webconf:db,$ldif_name)

  let $search_func := $function/csd:extension[@type='search' and @urn='urn:openhie.org:openinfoman:adapter:ldif']
  let $doc := 
    if ($search_func) 
    then
      let $csr :=
      <csd:careServicesRequest>
	<csd:function uuid="{$search_func}" >
	  <csd:requestParams >
	    {
	      if ($careServicesRequest/csd:function/csd:requestParams) then $careServicesRequest/csd:function/csd:requestParams/*
	    else $careServicesRequest/function/requestParams/*
	    }
	  </csd:requestParams>
	</csd:function>
      </csd:careServicesRequest>

      return csr_proc:process_CSR_stored_results($csd_webconf:db, $csd_doc,$careServicesRequest)
    else
      $csd_doc

  
  let $declare_ns := "declare namespace csd='urn:ihe:iti:csd:2013'; "

  let $entities_path := string($function/csd:extension[@type='entities' and @urn='urn:openhie.org:openinfoman:adapter:ldif'])
  let $entities := 
    if  ($entities_path) then
       xquery:eval( $declare_ns || "declare variable $doc external; $doc" || $entities_path, map { "csd_doc" := $doc}) 
    else
      $doc/csd:CSD/*/*
  
  let $f_func := 
    if (map:contains($processors,'facility')) then map:get($processors,'facility')
    else function($facility,$doc_name,$ldif_name)  {ldif:get_facility_entry($facility,$doc_name,$ldif_name)}

  let $o_func := 
    if (map:contains($processors,'organization')) then map:get($processors,'organization')
    else function($organization,$doc_name,$ldif_name)  {ldif:get_organization_entry($organization,$doc_name,$ldif_name)}

  let $p_func := 
    if (map:contains($processors,'provider')) then map:get($processors,'provider')
    else function($provider,$doc_name,$ldif_name)  {ldif:get_provider_entry($provider,$doc_name,$ldif_name)}

  let $items := 
    (
      for $entity in  $entities
      return
	if (local-name($entity) = 'organization') then $o_func($entity,$doc_name,$ldif_name)
	else if (local-name($entity) = 'faciltiy') then $f_func($entity,$doc_name,$ldif_name)
	else if (local-name($entity) = 'provider') then $p_func($entity,$doc_name,$ldif_name)
	else ()
    )

  return string-join($items, "&#10;")
};


declare function ldif:get_organization_entry($organization,$doc_name,$ldif_name) {
  let $provider := $organization/csd:contact/csd:provider
  let $t_dn := $provider/csd:demographic/csd:contactPoint/csd:codedType[@code='dn' and @codingScheme='urn:openhie.org:openinfoman:adapter:ldif']/text()
  let $dn := if ($t_dn) 
    then $t_dn 
    else 
       let $function := csr_proc:get_function_definition($csd_webconf:db,$ldif_name)
       let $t_ou := $function/csd:extension[@type='ou_organization' and @urn='urn:openhie.org:openinfoman:adapter:ldif']/text()
       let $ou := if ($t_ou) then $t_ou else "ou=organizations,dc=localhost"
       let $uid :=  string($provider/@oid)
       return "uid=" || $uid || $ou
  return 
    if (exists($provider)) then
      ldif:get_provider_entry($provider,$doc_name,$ldif_name,$dn)
    else  ()
};

declare function ldif:get_facility_entry($facility,$doc_name,$ldif_name) {
  let $provider := $facility/csd:contact/csd:provider
  let $t_dn := $provider/csd:demographic/csd:contactPoint/csd:codedType[@code='dn' and @codingScheme='urn:openhie.org:openinfoman:adapter:ldif']/text()
  let $dn := if ($t_dn) 
    then $t_dn 
    else 
       let $function := csr_proc:get_function_definition($csd_webconf:db,$ldif_name)
       let $t_ou := $function/csd:extension[@type='ou_facility' and @urn='urn:openhie.org:openinfoman:adapter:ldif']/text()
       let $ou := if ($t_ou) then $t_ou else "ou=facilities,dc=localhost"
       let $uid :=  string($provider/@oid)
       return "uid=" || $uid || "," || $ou 
  return
    if (exists($provider)) then
      ldif:get_provider_entry($provider,$doc_name,$ldif_name,$dn)
    else 
      ()
};


declare function ldif:get_provider_entry($provider,$doc_name,$ldif_name) {
  let $t_dn := $provider/csd:demographic/csd:contactPoint/csd:codedType[@code='dn' and @codingScheme='urn:openhie.org:openinfoman:adapter:ldif']/text()
  let $dn := if ($t_dn) 
    then $t_dn 
    else 
       let $function := csr_proc:get_function_definition($csd_webconf:db,$ldif_name)
       let $t_ou := $function/csd:extension[@type='ou_providers' and @urn='urn:openhie.org:openinfoman:adapter:ldif']/text()
       let $ou := if ($t_ou) then $t_ou else "ou=providers,dc=localhost"
       let $uid :=  string($provider/@oid)
       return "uid=" || $uid || "," || $ou 
  return ldif:get_provider_entry($provider,$doc_name,$ldif_name,$dn) 
};

declare function ldif:get_provider_entry($provider,$doc_name,$ldif_name,$dn) {
  let $t_mail := $provider/csd:demographic/csd:contactPoint/csd:codedType[@code='email' and @codingScheme='urn:openhie.org:openinfoman:adapter:ldif']/text()
  let $mail := 
    if ($t_mail) 
    then $t_mail
    else
      let $function := csr_proc:get_function_definition($csd_webconf:db,$ldif_name)
      let $t_mailserver := $function/csd:extension[@type='mailserver' and @urn='urn:openhie.org:openinfoman:adapter:ldif']/text()
      let $mailserver := if ($t_mailserver) then ($t_mailserver) else "localhost"
      let $uid :=  string($provider/@oid)
      return  $uid || "@" || $mailserver
    
  let $common_names := 
    for $cn in $provider/csd:demographic/csd:name/csd:commonName
    return concat( "cn: " , functx:trim($cn))

  let $surnames := 
    for $sn in $provider/csd:demographic/csd:name/csd:surname
    return concat( "sn: " , functx:trim($sn))

  let $given_names := 
    for $gn in $provider/csd:demographic/csd:name/csd:forename
    return concat( "gn: " , functx:trim($gn))

  let $roles :=
    for $spec in $provider/csd:specialization
    return concat( "businessCategory: " , string($spec/@code))


  let $t_mobile := $provider/csd:demographic/csd:contactPoint/csd:codedType[@code='mobile' and @codingScheme='urn:openhie.org:openinfoman:adapter:ldif']/text() 
  let $mobile := 
    if ($t_mobile)
     then $t_mobile
     else ()

  let $t_pager := $provider/csd:demographic/csd:contactPoint/csd:codedType[@code='pager' and @codingScheme='urn:openhie.org:openinfoman:adapter:ldif']/text()
  let $pager := 
    if ($t_pager) 
     then $t_pager
     else ()
(:
let $photo  := $provider/csd:demographic/csd:extension[@type='photograph' and @oid='urn.openhie.org:openinfoman:adapter:ldif']
//photo  = base64encoding($photo)
//perhaps these xpaths should be configurable in the careservices function so you could od
let $t_xpaths := 
let $xpaths := 
   if ($t_expaths) 
   then ($t_expaths) 
   else ( "$function/csd:extension[@type='xpaths_photo' and @urn='urn:openhie.org:openinfoman:adapter:csv']")

let $photos := for $xpath in $xpaths
  for $found_photo in xquery:eval( "$provider./" || $xpath, map { "provider" := $provider}) 
  let  $val := string($found_photo)
  return concat("photo: " . $base64Encode($val))

:)

  let $object_classes := 
    (
      "objectClass: person"
      ,"objectClass: inetOrgPerson"
      ,"objectClass: organizationalPerson"
      ,"objectClass: top"
    )
 
  let $ldif_entry := 
    (
    "dn: " || $dn
    ,$object_classes
    ,$common_names
    ,$surnames
    ,$given_names
    ,"mail: " ||  $mail
    ,if ($mobile) then "mobile: " || $mobile else ()
    ,if ($pager) then "pager: " || $pager else ()
    ,$roles
    )
  (: need extra new line after entries :)
  return string-join ( ($ldif_entry,"") ,  "&#10;")
  
};







