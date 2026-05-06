extends RefCounted
class_name HostBridge
## Next.js / üst sayfa ile iletişim (ör. tam ekran). Web export dışında çalışmaz.
##
## Üst pencerede örnek:
##   window.addEventListener('message', (e) => {
##     if (e.data?.source !== 'game-ge' || e.data?.action !== 'toggle-fullscreen') return;
##     document.getElementById('oyun-kapsayici')?.requestFullscreen?.();
##   });


static func notify_parent_toggle_fullscreen() -> void:
	if not OS.has_feature("web"):
		return
	JavaScriptBridge.eval("""
(function(){try{window.parent.postMessage({source:'game-ge',action:'toggle-fullscreen'},'*');}catch(e){}})()
""")

