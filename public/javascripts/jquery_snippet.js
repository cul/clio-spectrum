function CSRFProtection(xhr) {
 var token = $('meta[name="csrf-token"]').attr('content');
 if (token) xhr.setRequestHeader('X-CSRF-Token', token);
}
if ('ajaxPrefilter' in $) $.ajaxPrefilter(function(options, originalOptions, xhr) { CSRFProtection(xhr); });
else $(document).ajaxSend(function(e, xhr) { CSRFProtection(xhr); });

