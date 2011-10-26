function CSRFProtection(xhr) {
 var token = $('meta[name="csrf-token"]').attr('content');
 if (token) xhr.setRequestHeader('X-CSRF-Token', token);
}
if ('ajaxPrefilter' in $) $.ajaxPrefilter(function(options, originalOptions, xhr) { 
 if (options.url.indexOf("holdings/fetch") == -1 && options.url.indexOf("holdings/retrieve") == -1)
   CSRFProtection(xhr); });
else $(document).ajaxSend(function(e, xhr) { CSRFProtection(xhr); });


