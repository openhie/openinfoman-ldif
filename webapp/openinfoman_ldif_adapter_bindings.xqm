module namespace page = 'http://basex.org/modules/web-page';

import module namespace ldif = "https://github.com/openhie/openinfoman/adapter/ldif";
import module namespace csd_webconf =  "https://github.com/openhie/openinfoman/csd_webconf";
import module namespace csd_dm = "https://github.com/openhie/openinfoman/csd_dm";
import module namespace csr_proc = "https://github.com/openhie/openinfoman/csr_proc";

declare namespace html = "http://www.w3.org/1999/xhtml";


declare namespace csd = "urn:ihe:iti:csd:2013";


declare function page:redirect($redirect as xs:string) as element(restxq:redirect)
{
  <restxq:redirect>{ $redirect }</restxq:redirect>
};

declare function page:nocache($response) {
(<http:response status="200" message="OK">  

  <http:header name="Cache-Control" value="must-revalidate,no-cache,no-store"/>
</http:response>,
$response)
};




(:Supposed to be linked into header of a web-page, such as the OpenHIE Health Worker Registry Management Interface :)
declare
  %rest:path("/CSD/adapter/ldif/{$ldif_name}")
  %rest:GET
  %output:method("xhtml")
  function page:show_ldifs_on_docs($ldif_name) 
{ 
  if ( ldif:is_ldif_function($ldif_name)) then 
    let $ldifs := 
      <ul>
        {
  	  for $doc_name in csd_dm:registered_documents($csd_webconf:db)      
	  return
  	  <li>
	  
	    <a href="{$csd_webconf:baseurl}CSD/adapter/ldif/{$ldif_name}/{$doc_name}">{string($doc_name)}</a>
	  </li>
	}
      </ul>

   let $contents :=
     (
	<a href="{$csd_webconf:baseurl}CSD/adapter/ldif">LDIF Adapters</a>
        ,$ldifs
	)
   return page:wrapper($contents)
  else
  let $function := csr_proc:get_function_definition($csd_webconf:db,$ldif_name)
  let $contents := 
(
   <p>
     Invalid Ldif ({$ldif_name})
   </p>
   ,<p>
     <pre class='bodycontainer scrollable pull-left' style='overflow:scroll;font-family: monospace;white-space: pre;'>
       {
	 $function
       }
     </pre>
   </p>
)
  return  page:wrapper($contents)
};



declare
  %rest:path("/CSD/adapter/ldif/{$ldif_name}/{$doc_name}/run")
  %rest:POST
  %output:method("text")
  function page:run_script($ldif_name,$doc_name)
{
  let $careServicesRequest := 
    <csd:careServicesRequest >
      <csd:function uuid="{$ldif_name}"/>
    </csd:careServicesRequest>
  let $doc := csd_dm:open_document($csd_webconf:db,$doc_name)
  let $contents := csr_proc:process_CSR_stored_results($csd_webconf:db, $doc,$careServicesRequest)
  return $contents
};

declare
  %rest:path("/CSD/adapter/ldif/{$ldif_name}/{$doc_name}")
  %output:method("xhtml")
  %rest:GET
  function page:run_script_get($ldif_name,$doc_name)
{
  let $contents := <div class='container'>
    <p>Ldif: 	    <a href="{$csd_webconf:baseurl}CSD/adapter/ldif/{$ldif_name}">{$ldif_name}</a></p>
    <p>Resource Document: <a href="{$csd_webconf:baseurl}CSD/adapter/ldif/{$ldif_name}/{$doc_name}">{$doc_name}</a></p>
    <form method='post' action="{$csd_webconf:baseurl}CSD/adapter/ldif/{$ldif_name}/{$doc_name}/run"  enctype="multipart/form-data">
      <input type='submit' value='Export LDIF'/>
    </form>
  </div>
  return page:wrapper($contents)
   
};






declare function page:wrapper($content) {
  let $header :=     <link rel="stylesheet" type="text/css" media="screen"   href="{$csd_webconf:baseurl}static/bootstrap-datetimepicker/css/bootstrap-datetimepicker.min.css"/>
  return csd_webconf:wrapper($content,$header)
};
