#!/bin/builder.sh
skip=( false false false false false false )
step=1
prefix="setup"
source="https://raw.github.com/michaelsalisbury/builder/master/defaults/${scriptName}"
#source=http://192.168.248.24/config/$scriptName

#function includes(){
#	functions.*.sh
#	../functions/functions.*.sh
#}

# GLOBAL VARIABLES
function global_variables(){
	read -d $'' GOOGLE_CHROME_URLS <<-END-OF-URLS
		http://www.cos.ucf.edu/
		http://www.cos.ucf.edu/it/
		https://www.google.com/
	END-OF-URLS
}

function setup_skel_Structure(){
	desc Build skel directory structure
	###############################################################################
	mkdir -p  /etc/skel/.config/google-chrome/Default
	chmod 700 /etc/skel/.config
	chmod 700 /etc/skel/.config/google-chrome
	chmod 700 /etc/skel/.config/google-chrome/Default
	mkdir -p  /etc/skel/.config/xfce4
	chmod 700 /etc/skel/.config/xfce4
	mkdir -p  /etc/skel/.local/share/applications
	chmod 700 /etc/skel/.local/share
	mkdir -p  /etc/skel/.local/share/xfce4/helpers
}
function setup_xfce_defaults(){
	desc Set Chrome as the default browser
	###############################################################################
	cp -f "/usr/share/applications/google-chrome.desktop" \
	      "/etc/skel/.local/share/xfce4/helpers/".
	local helpers='/etc/skel/.config/xfce4/helpers.rc'
	touch                    "${helpers}"
	chmod 600                "${helpers}"
	sed -i '/^WebBrowser=/d' "${helpers}"
	cat <<-END-OF-APPEND >>  "${helpers}"
		WebBrowser=google-chrome
	END-OF-APPEND
	###############################################################################
	local mimeapps='/etc/skel/.local/share/applications/mimeapps.list'
	touch  "${mimeapps}"
	if `egrep "^\[Default Applications\]$" "${mimeapps}" &> /dev/null`; then
		cat <<-SED | sed -i -f <(cat) "${mimeapps}"
			/^\[Default Applications\]$/,/^\[.*\]$/ {
				/^text\/html=/d
				/^x-scheme-handler\/http=/d
				/^x-scheme-handler\/https=/d
				/^x-scheme-handler\/about=/d
				/^x-scheme-handler\/unknown=/d
			}
		SED
	else
		cat <<-END-OF-APPEND >> "${mimeapps}"
			[Default Applications]
		END-OF-APPEND
	fi
	cat <<-SED | sed -i -f <(cat) "${mimeapps}"
		/^\[Default Applications\]$/ {
			atext\/html=google-chrome.desktop
			ax-scheme-handler\/http=google-chrome.desktop
			ax-scheme-handler\/https=google-chrome.desktop
			ax-scheme-handler\/about=google-chrome.desktop
			ax-scheme-handler\/unknown=google-chrome.desktop
		}
	SED
}
function setup_gnome_defaults(){
	desc Set Gnome Defaults via gcontool\-2
	###############################################################################
	local opt='--direct --config-source xml:readwrite:/etc/gconf/gconf.xml.defaults'

	gconftool-2 $opt -t string -s /desktop/gnome/applications/browser/exec    "/opt/google/chrome/google-chrome"
	gconftool-2 $opt -t bool   -s /desktop/gnome/applications/browser/nremote true
	gconftool-2 $opt -t string -s /desktop/gnome/url-handlers/http/command    "/opt/google/chrome/google-chrome %s"
	gconftool-2 $opt -t bool   -s /desktop/gnome/url-handlers/http/enabled    true
	gconftool-2 $opt -t string -s /desktop/gnome/url-handlers/https/command   "/opt/google/chrome/google-chrome %s"
	gconftool-2 $opt -t bool   -s /desktop/gnome/url-handlers/https/enabled   true
	gconftool-2 $opt -t string -s /desktop/gnome/url-handlers/unknown/command "/opt/google/chrome/google-chrome %s"
	gconftool-2 $opt -t string -s /desktop/gnome/url-handlers/about/command   "/opt/google/chrome/google-chrome %s"
}

function setup_files(){
	desc Set Chrome\'s default preferences \+ desktop file
	###############################################################################
	cat_preferences >> "/etc/skel/.config/google-chrome/Default/Preferences"
	chmod 600          "/etc/skel/.config/google-chrome/Default/Preferences"
	cat_local_state >> "/etc/skel/.config/google-chrome/Local State"
	chmod 600          "/etc/skel/.config/google-chrome/Local State"
	touch              "/etc/skel/.config/google-chrome/First Run"
	chmod 600          "/etc/skel/.config/google-chrome/First Run"

}
#######################################################################################
#######################################################################################
# Support functions below
#######################################################################################
#######################################################################################

function setup_cat_preferences(){
	echo "${GOOGLE_CHROME_URLS}" | sed 's/\(^\|$\)/"/g'
	echo

	return


	cat << END-OF-PREFERENCES
$'{'
   "backup": {
      "_signature": "wrshpwGoyIry3vvW05eHh7Wylxonfm5gLuyfVLdT8RM=",
      "_version": 4,
      "extensions": {
         "ids": [ "ahfgeienlihckogmohjhadlkjgocpleb", "apdfllckaahabafndbhieahigkjlhalf", "blpcfgokakmgnkcojhhkbfbldkacnbeo", "coobgpohoikkiipiblmjeljniedjpjpf", "pjkljhegncpnkpknbcohdijeoejaedia" ]
      },
      "homepage": "",
      "homepage_is_newtabpage": true,
      "session": {
         "restore_on_startup": 4,
         "urls_to_restore_on_startup": [ "http://www.cos.ucf.edu/", "http://www.cos.ucf.edu/it/", "https://www.google.com/" ]
      }
   },
   "browser": {
      "clear_lso_data_enabled": true,
      "last_known_google_url": "http://www.google.com/",
      "last_prompted_google_url": "http://www.google.com/",
      "pepper_flash_settings_enabled": true,
      "window_placement": {
         "bottom": 982,
         "left": 0,
         "maximized": true,
         "right": 1050,
         "top": 0,
         "work_area_bottom": 1033,
         "work_area_left": 0,
         "work_area_right": 1073,
         "work_area_top": 31
      }
   },
   "cloud_print": {
      "email": ""
   },
   "countryid_at_install": 21843,
   "default_apps_install_state": 3,
   "default_search_provider": {
      "enabled": true,
      "encodings": "UTF-8",
      "icon_url": "http://www.google.com/favicon.ico",
      "id": "2",
      "instant_url": "{google:baseURL}webhp?sourceid=chrome-instant&{google:RLZ}{google:instantEnabledParameter}ie={inputEncoding}",
      "keyword": "google.com",
      "name": "Google",
      "prepopulate_id": "1",
      "search_url": "{google:baseURL}search?q={searchTerms}&{google:RLZ}{google:acceptedSuggestion}{google:originalQueryForSuggestion}{google:assistedQueryStats}{google:searchFieldtrialParameter}sourceid=chrome&ie={inputEncoding}",
      "suggest_url": "{google:baseSuggestURL}search?{google:searchFieldtrialParameter}client=chrome&hl={language}&q={searchTerms}&sugkey={google:suggestAPIKeyParameter}"
   },
   "dns_prefetching": {
      "host_referral_list": [ 2, [ "http://an.tacoda.net/", [ "http://an.tacoda.net/", 2.2733802, "http://ar.atwola.com/", 2.6037003999999997, "http://leadback.advertising.com/", 2.6037003999999997, "http://rt.legolas-media.com/", 2.2733802, "http://tacoda.at.atwola.com/", 2.2733802 ] ], [ "http://golug.org/", [ "http://golug.org/", 7.888823599999998 ] ], [ "http://googleads.g.doubleclick.net/", [ "http://www.google.com/", 2.6037003999999997, "https://googleads.g.doubleclick.net/", 2.6037003999999997 ] ], [ "http://js.bizographics.com/", [ "http://an.tacoda.net/", 2.6037003999999997, "http://js.bizographics.com/", 3.2643407999999994, "http://load.exelator.com/", 3.2643407999999994, "http://tags.bluekai.com/", 3.2643407999999994, "http://www.bkrtx.com/", 2.2733802 ] ], [ "http://load.exelator.com/", [ "http://d.p-td.com/", 2.2733802, "http://d.turn.com/", 2.2733802, "http://dm.de.mookie1.com/", 2.2733802, "http://segment-pixel.invitemedia.com/", 2.2733802, "http://uav.tidaltv.com/", 2.2733802, "https://load.s3.amazonaws.com/", 2.2733802, "https://loadm.exelator.com/", 2.2733802, "https://t.mookie1.com/", 2.6037003999999997 ] ], [ "http://platform.twitter.com/", [ "http://cdn.api.twitter.com/", 2.2733802, "http://p.twitter.com/", 2.2733802, "http://r.twimg.com/", 2.2733802 ] ], [ "http://tag.crsspxl.com/", [ "http://a.collective-media.net/", 2.2733802, "http://ad.yieldmanager.com/", 2.2733802, "http://cm.g.doubleclick.net/", 2.2733802, "http://d.turn.com/", 2.2733802, "http://ib.adnxs.com/", 2.2733802, "http://segment-pixel.invitemedia.com/", 2.2733802, "http://sync.mathtag.com/", 2.6037003999999997, "http://tag.crsspxl.com/", 2.9340205999999998 ] ], [ "http://tags.bluekai.com/", [ "http://cm.g.doubleclick.net/", 2.2733802, "http://r.nexac.com/", 2.2733802, "http://tags.bluekai.com/", 2.6037003999999997 ] ], [ "http://tomshardware.com/", [ "http://www.tomshardware.com/", 2.6037003999999997 ] ], [ "http://www.facebook.com/", [ "http://static.ak.fbcdn.net/", 1.7948122942399998 ] ], [ "http://www.tomshardware.com/", [ "http://js.bizographics.com/", 3.924981199999999, "http://platform.twitter.com/", 2.6037003999999997, "http://pubads.g.doubleclick.net/", 3.924981199999999, "http://static.ak.facebook.com/", 2.6037003999999997, "http://tag.crsspxl.com/", 2.6037003999999997, "http://www.facebook.com/", 2.6037003999999997, "http://www.google-analytics.com/", 3.924981199999999, "https://plusone.google.com/", 3.2643407999999994, "https://s-static.ak.facebook.com/", 2.6037003999999997, "https://www.facebook.com/", 2.6037003999999997 ] ], [ "https://2542116.fls.doubleclick.net/", [ "https://ad.yieldmanager.com/", 3.8132369852359993, "https://cm.g.doubleclick.net/", 2.529573049612, "https://cookex.amp.yahoo.com/", 2.529573049612, "https://g-pixel.invitemedia.com/", 2.529573049612, "https://googleads.g.doubleclick.net/", 3.1714050174239996, "https://segment-pixel.invitemedia.com/", 2.529573049612, "https://www.google.com/", 2.529573049612, "https://www.googleadservices.com/", 3.4923210013299997 ] ], [ "https://plusone.google.com/", [ "https://apis.google.com/", 2.2733802, "https://plusone.google.com/", 1.8012606080910258, "https://ssl.gstatic.com/", 2.6037003999999997 ] ], [ "https://www.google.com/", [ "https://2542116.fls.doubleclick.net/", 1.6695182127439199, "https://apis.google.com/", 1.6695182127439199, "https://fls.doubleclick.net/", 2.09312731149984, "https://fonts.googleapis.com/", 1.4577136633659602, "https://plusone.google.com/", 1.6695182127439199, "https://ssl.google-analytics.com/", 1.6695182127439199, "https://ssl.gstatic.com/", 1.99983841274392, "https://themes.googleusercontent.com/", 2.09312731149984, "https://tools.google.com/", 1.4577136633659602, "https://www.google.com/", 6.972250055901478 ] ] ],
      "startup_list": [ 1, "http://b.scorecardresearch.com/", "http://golug.org/", "http://m.bestofmedia.com/", "http://media.bestofmicro.com/", "http://partner.googleadservices.com/", "http://tomshardware.com/", "http://tracking.tomsguide.com/", "http://w.estat.com/", "http://www.tomshardware.com/", "https://www.google.com/" ]
   },
   "download": {
      "directory_upgrade": true,
      "extensions_to_open": ""
   },
   "extensions": {
      "autoupdate": {
         "next_check": "12997989566284287"
      },
      "chrome_url_overrides": {
         "bookmarks": [ "chrome-extension://eemcgdkfndhakfknompkggombfjjjeno/main.html" ]
      },
      "settings": {
         "ahfgeienlihckogmohjhadlkjgocpleb": {
            "active_permissions": {
               "api": [ "appNotifications", "management", "webstorePrivate" ]
            },
            "app_launcher_ordinal": "n",
            "page_ordinal": "n"
         },
         "apdfllckaahabafndbhieahigkjlhalf": {
            "ack_external": true,
            "active_permissions": {
               "api": [ "background", "clipboardRead", "clipboardWrite", "notifications", "unlimitedStorage" ]
            },
            "app_launcher_ordinal": "y",
            "from_bookmark": false,
            "from_webstore": true,
            "granted_permissions": {
               "api": [ "background", "clipboardRead", "clipboardWrite", "notifications", "unlimitedStorage" ]
            },
            "install_time": "12997988697072586",
            "location": 1,
            "manifest": {
               "app": {
                  "launch": {
                     "web_url": "https://drive.google.com/"
                  },
                  "urls": [ "http://docs.google.com/", "http://drive.google.com/", "https://docs.google.com/", "https://drive.google.com/" ]
               },
               "background": {
                  "allow_js_access": false
               },
               "current_locale": "en_US",
               "default_locale": "en_US",
               "description": "Google Drive: create, share and keep all your stuff in one place.",
               "icons": {
                  "128": "128.png"
               },
               "key": "MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDIl5KlKwL2TSkntkpY3naLLz5jsN0YwjhZyObcTOK6Nda4Ie21KRqZau9lx5SHcLh7pE2/S9OiArb+na2dn7YK5EvH+aRXS1ec3uxVlBhqLdnleVgwgwlg5fH95I52IeHcoeK6pR4hW/Nv39GNlI/Uqk6O6GBCCsAxYrdxww9BiQIDAQAB",
               "manifest_version": 2,
               "name": "Google Drive",
               "offline_enabled": true,
               "options_page": "https://drive.google.com/settings",
               "permissions": [ "background", "clipboardRead", "clipboardWrite", "notifications", "unlimitedStorage" ],
               "update_url": "http://clients2.google.com/service/update2/crx",
               "version": "6.2"
            },
            "page_ordinal": "n",
            "path": "apdfllckaahabafndbhieahigkjlhalf/6.2_0",
            "state": 1,
            "was_installed_by_default": true
         },
         "blpcfgokakmgnkcojhhkbfbldkacnbeo": {
            "ack_external": true,
            "active_permissions": {
               "api": [ "appNotifications" ]
            },
            "app_launcher_ordinal": "t",
            "from_bookmark": true,
            "from_webstore": true,
            "granted_permissions": {
               "api": [ "appNotifications" ]
            },
            "install_time": "12997988696860800",
            "location": 1,
            "manifest": {
               "app": {
                  "launch": {
                     "container": "tab",
                     "web_url": "http://www.youtube.com/"
                  },
                  "web_content": {
                     "enabled": true,
                     "origin": "http://www.youtube.com"
                  }
               },
               "current_locale": "en_US",
               "default_locale": "en",
               "description": "The world's most popular online video community.",
               "icons": {
                  "128": "128.png"
               },
               "key": "MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDC/HotmFlyuz5FaHaIbVBhhL4BwbcUtsfWwzgUMpZt5ZsLB2nW/Y5xwNkkPANYGdVsJkT2GPpRRIKBO5QiJ7jPMa3EZtcZHpkygBlQLSjMhdrAKevpKgIl6YTkwzNvExY6rzVDzeE9zqnIs33eppY4S5QcoALMxuSWlMKqgFQjHQIDAQAB",
               "name": "YouTube",
               "permissions": [ "appNotifications" ],
               "update_url": "http://clients2.google.com/service/update2/crx",
               "version": "4.2.5"
            },
            "page_ordinal": "n",
            "path": "blpcfgokakmgnkcojhhkbfbldkacnbeo/4.2.5_0",
            "state": 1,
            "was_installed_by_default": true
         },
         "coobgpohoikkiipiblmjeljniedjpjpf": {
            "ack_external": true,
            "app_launcher_ordinal": "x",
            "from_bookmark": true,
            "from_webstore": true,
            "install_time": "12997988697042092",
            "location": 1,
            "manifest": {
               "app": {
                  "launch": {
                     "web_url": "http://www.google.com/webhp?source=search_app"
                  },
                  "urls": [ "*://www.google.com/search", "*://www.google.com/webhp", "*://www.google.com/imgres" ]
               },
               "current_locale": "en_US",
               "default_locale": "en",
               "description": "The fastest way to search the web.",
               "icons": {
                  "128": "128.png",
                  "16": "16.png",
                  "32": "32.png",
                  "48": "48.png"
               },
               "key": "MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDIiso3Loy5VJHL40shGhUl6it5ZG55XB9q/2EX6aa88jAxwPutbCgy5d9bm1YmBzLfSgpX4xcpgTU08ydWbd7b50fbkLsqWl1mRhxoqnN01kuNfv9Hbz9dWWYd+O4ZfD3L2XZs0wQqo0y6k64n+qeLkUMd1MIhf6MR8Xz1SOA8pwIDAQAB",
               "name": "Google Search",
               "update_url": "http://clients2.google.com/service/update2/crx",
               "version": "0.0.0.19"
            },
            "page_ordinal": "n",
            "path": "coobgpohoikkiipiblmjeljniedjpjpf/0.0.0.19_0",
            "state": 1,
            "was_installed_by_default": true
         },
         "pjkljhegncpnkpknbcohdijeoejaedia": {
            "ack_external": true,
            "active_permissions": {
               "api": [ "notifications" ]
            },
            "app_launcher_ordinal": "w",
            "from_bookmark": false,
            "from_webstore": true,
            "granted_permissions": {
               "api": [ "notifications" ]
            },
            "install_time": "12997988696981038",
            "location": 1,
            "manifest": {
               "app": {
                  "launch": {
                     "container": "tab",
                     "web_url": "https://mail.google.com/mail/ca"
                  },
                  "urls": [ "*://mail.google.com/mail/ca" ]
               },
               "current_locale": "en_US",
               "default_locale": "en",
               "description": "Fast, searchable email with less spam.",
               "icons": {
                  "128": "128.png"
               },
               "key": "MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDCuGglK43iAz3J9BEYK/Mz6ZhloIMMDqQSAaf3vJt4eHbTbSDsu4WdQ9dQDRcKlg8nwQdePBt0C3PSUBtiSNSS37Z3qEGfS7LCju3h6pI1Yr9MQtxw+jUa7kXXIS09VV73pEFUT/F7c6Qe8L5ZxgAcBvXBh1Fie63qb02I9XQ/CQIDAQAB",
               "name": "Gmail",
               "options_page": "https://mail.google.com/mail/ca/#settings",
               "permissions": [ "notifications" ],
               "update_url": "http://clients2.google.com/service/update2/crx",
               "version": "7"
            },
            "page_ordinal": "n",
            "path": "pjkljhegncpnkpknbcohdijeoejaedia/7_0",
            "state": 1,
            "was_installed_by_default": true
         }
      }
   },
   "homepage": "",
   "homepage_is_newtabpage": true,
   "net": {
      "http_server_properties": {
         "servers": {
            "apis.google.com:443": {
               "settings": {
                  "4": 100,
                  "5": 50,
                  "6": 0
               },
               "supports_spdy": true
            },
            "fls.doubleclick.net:443": {
               "settings": {
                  "4": 100,
                  "5": 32,
                  "6": 0
               },
               "supports_spdy": true
            },
            "fonts.googleapis.com:443": {
               "settings": {
                  "4": 100,
                  "5": 32,
                  "6": 0
               },
               "supports_spdy": true
            },
            "googleads.g.doubleclick.net:443": {
               "settings": {
                  "4": 100,
                  "5": 32,
                  "6": 0
               },
               "supports_spdy": true
            },
            "ssl.google-analytics.com:443": {
               "settings": {
                  "4": 100,
                  "5": 32,
                  "6": 0
               },
               "supports_spdy": true
            },
            "ssl.gstatic.com:443": {
               "settings": {
                  "4": 100,
                  "5": 32,
                  "6": 0
               },
               "supports_spdy": true
            },
            "themes.googleusercontent.com:443": {
               "settings": {
                  "4": 100,
                  "5": 62,
                  "6": 0
               },
               "supports_spdy": true
            },
            "www.google.com:443": {
               "settings": {
                  "4": 100,
                  "5": 81,
                  "6": 0
               },
               "supports_spdy": true
            },
            "www.googleadservices.com:443": {
               "settings": {
                  "4": 100,
                  "5": 32,
                  "6": 0
               },
               "supports_spdy": true
            }
         },
         "version": 1
      }
   },
   "ntp": {
      "app_page_names": [ "Apps" ],
      "promo_resource_cache_update": "1353515095.632644"
   },
   "plugins": {
      "enabled_internal_pdf3": true,
      "enabled_nacl": true,
      "last_internal_directory": "/opt/google/chrome",
      "plugins_list": [ {
         "enabled": true,
         "name": "Shockwave Flash",
         "path": "/opt/google/chrome/PepperFlash/libpepflashplayer.so",
         "version": "11.5.31.2"
      }, {
         "enabled": true,
         "name": "Chrome Remote Desktop Viewer",
         "path": "internal-remoting-viewer",
         "version": ""
      }, {
         "enabled": true,
         "name": "Native Client",
         "path": "/opt/google/chrome/libppGoogleNaClPluginChrome.so",
         "version": ""
      }, {
         "enabled": true,
         "name": "Chrome PDF Viewer",
         "path": "/opt/google/chrome/libpdf.so",
         "version": ""
      }, {
         "enabled": true,
         "name": "Gnome Shell Integration",
         "path": "/usr/lib/mozilla/plugins/libgnome-shell-browser-plugin.so",
         "version": ""
      }, {
         "enabled": true,
         "name": "iTunes Application Detector",
         "path": "/usr/lib/mozilla/plugins/librhythmbox-itms-detection-plugin.so",
         "version": ""
      }, {
         "enabled": true,
         "name": "VLC Multimedia Plugin (compatible Totem 3.4.3)",
         "path": "/usr/lib/mozilla/plugins/libtotem-cone-plugin.so",
         "version": ""
      }, {
         "enabled": true,
         "name": "Windows Media Player Plug-in 10 (compatible; Totem)",
         "path": "/usr/lib/mozilla/plugins/libtotem-gmp-plugin.so",
         "version": ""
      }, {
         "enabled": true,
         "name": "DivX\u00AE Web Player",
         "path": "/usr/lib/mozilla/plugins/libtotem-mully-plugin.so",
         "version": ""
      }, {
         "enabled": true,
         "name": "QuickTime Plug-in 7.6.6",
         "path": "/usr/lib/mozilla/plugins/libtotem-narrowspace-plugin.so",
         "version": ""
      }, {
         "enabled": true,
         "name": "Adobe Flash Player"
      }, {
         "enabled": true,
         "name": "Chrome PDF Viewer"
      }, {
         "enabled": true,
         "name": "Chrome Remote Desktop Viewer"
      }, {
         "enabled": true,
         "name": "DivX\u00AE Web Player"
      }, {
         "enabled": true,
         "name": "Gnome Shell Integration"
      }, {
         "enabled": true,
         "name": "Native Client"
      }, {
         "enabled": true,
         "name": "QuickTime Plug-in 7.6.6"
      }, {
         "enabled": true,
         "name": "VLC Multimedia Plugin (compatible Totem 3.4.3)"
      }, {
         "enabled": true,
         "name": "Windows Media Player Plug-in 10 (compatible; Totem)"
      }, {
         "enabled": true,
         "name": "iTunes Application Detector"
      } ]
   },
   "profile": {
      "avatar_index": 0,
      "content_settings": {
         "clear_on_exit_migrated": true,
         "pref_version": 1
      },
      "created_by_version": "23.0.1271.64",
      "exited_cleanly": true,
      "local_profile_id": 9716779,
      "name": "First user"
   },
   "promo": {
      "ntp_notification_promo": [ {
         "closed": true,
         "end": 0.0,
         "gplus_required": false,
         "group": 0,
         "increment": 1,
         "increment_frequency": 0,
         "increment_max": 0,
         "max_views": 0,
         "num_groups": 100,
         "segment": 0,
         "start": 0.0,
         "text": "",
         "views": 0
      } ]
   },
   "session": {
      "restore_on_startup": 4,
      "restore_on_startup_migrated": true,
      "urls_to_restore_on_startup": [ "http://golug.org/", "http://tomshardware.com/", "https://www.google.com/" ]
   },
   "sync": {
      "suppress_start": true
   },
   "sync_promo": {
      "startup_count": 1,
      "view_count": 1
   }
\}
END-OF-PREFERENCES
}


function cat_local_state(){
	cat << END-OF-LOCALSTATE
\{
   "browser": {
      "last_redirect_origin": ""
   },
   "local_state": {
      "multiple_profile_prefs_version": 7
   },
   "ntp": {
      "promo_locale": "en-US",
      "promo_version": 7
   },
   "profile": {
      "info_cache": {
         "Default": {
            "avatar_icon": "chrome://theme/IDR_PROFILE_AVATAR_0",
            "background_apps": false,
            "name": "First user",
            "user_name": ""
         }
      },
      "last_active_profiles": [ "Default" ],
      "last_used": "Default"
   },
   "show-first-run-bubble": false,
   "show-welcome-page": false,
   "shutdown": {
      "num_processes": 0,
      "num_processes_slow": 0,
      "type": 0
   },
   "uninstall_metrics": {
      "installation_date2": "1353554803",
      "launch_count": "1"
   },
   "user_experience_metrics": {
      "low_entropy_source": 4045,
      "session_id": 0,
      "stability": {
         "breakpad_registration_fail": 1,
         "breakpad_registration_ok": 0,
         "crash_count": 0,
         "debugger_not_present": 1,
         "debugger_present": 0,
         "exited_cleanly": false,
         "incomplete_session_end_count": 0,
         "last_timestamp_sec": "0",
         "launch_count": 1,
         "launch_time_sec": "1353554803",
         "page_load_count": 0,
         "renderer_crash_count": 0,
         "renderer_hang_count": 0,
         "session_end_completed": true,
         "stats_buildtime": "1351682027",
         "stats_version": "23.0.1271.64-64"
      }
   },
   "variations_seed": "CihlYzJlZjZmNzg1MWRhMDk5Y2U4OTE0MjBiNTA2NGMxYTc0OWE5MmQ0EnAKCEFzeW5jRG5zGMSb44oFOABCClN5c3RlbURuc0FKDgoKU3lzdGVtRG5zQRAZSg4KClN5c3RlbURuc0IQGUoNCglBc3luY0Ruc0EQGUoNCglBc3luY0Ruc0IQGVISEgQyNC4qIAAgASgAKAEoAigDEpABChhDYWNoZVNlbnNpdGl2aXR5QW5hbHlzaXMYxM2IhwVCAk5vSgYKAk5vECRKDAoIQ29udHJvbEEQCEoMCghDb250cm9sQhAISggKBDEwMEEQCEoICgQxMDBCEAhKCAoEMjAwQRAISggKBDIwMEIQCEoICgQ0MDBBEAhKCAoENDAwQhAIUgogACABKAAoASgCEmMKI1VNQS1EeW5hbWljLUJpbmFyeS1Vbmlmb3JtaXR5LVRyaWFsGICckqUFOAFCB2RlZmF1bHRKEAoHZGVmYXVsdBBQGKm2yQFKEQoIZ3JvdXBfMDEQFBiqtskBUgYgACABIAISXwojVU1BLUR5bmFtaWMtQmluYXJ5LVVuaWZvcm1pdHktVHJpYWwYgJySpQU4AUIHZGVmYXVsdEoQCgdkZWZhdWx0EFoYqbbJAUoRCghncm91cF8wMRAKGKq2yQFSAiADEpUBCg1Ib3N0Q2FjaGVTaXplGMSb44oFOABCB0RlZmF1bHRKCwoHRGVmYXVsdBAASggKBDEwMEEQCkoICgQxMDBCEApKCAoEMzAwQRAKSggKBDMwMEIQCkoJCgUxMDAwQRAKSgkKBTEwMDBCEApKCQoFMzAwMEEQCkoJCgUzMDAwQhAKUhISBDI1LiogACABKAAoASgCKAMSRAoNSW5maW5pdGVDYWNoZRjEtI2WBTgBQgJOb0oHCgJObxDmB0oHCgNZZXMQAUoLCgdDb250cm9sEAFSCCADKAAoASgCEjYKDkluc3RhbnRDaGFubmVsGIDqvY4FOAFCBEJldGFKDgoEQmV0YRDoBxjig8oBUgYgAigAKAMSNAoOSW5zdGFudENoYW5uZWwYgOq9jgU4AUIDRGV2Sg0KA0RldhDoBxjjg8oBUgYgASgAKAMSOgoOSW5zdGFudENoYW5uZWwYgOq9jgU4AUIGU3RhYmxlShAKBlN0YWJsZRDoBxjkg8oBUgYgAygAKAMSowEKDEluc3RhbnREdW1teRiA6r2OBTgBQgxEZWZhdWx0R3JvdXBKEQoHQ29udHJvbBCsAhjKg8oBShUKC0V4cGVyaW1lbnQxEKwCGMuDygFKHQoURXhwZXJpbWVudDJfRElTQUJMRUQQMhjMg8oBShQKC0V4cGVyaW1lbnQzEDIY4YPKAUoWCgxEZWZhdWx0R3JvdXAQrAIYyYPKAVIGIAAoACgDEqEBCgxJbnN0YW50RHVtbXkYgOq9jgU4AUIMRGVmYXVsdEdyb3VwShAKB0NvbnRyb2wQZBjKg8oBShQKC0V4cGVyaW1lbnQxEGQYy4PKAUodChRFeHBlcmltZW50Ml9ESVNBQkxFRBAyGMyDygFKFAoLRXhwZXJpbWVudDMQMhjhg8oBShYKDERlZmF1bHRHcm91cBC8BRjJg8oBUgYgASgAKAMSVwoMTmV3VGFiQnV0dG9uGIDOiIcFOAFCB2RlZmF1bHRKCwoHZGVmYXVsdBBiSgsKB0NvbnRyb2wQAUoICgRQbHVzEAFSEhIMMjEuMC4xMTgwLjE1IAMoABI2Cg5TQkludGVyc3RpdGlhbBjA0o2JBTgBQgJWMUoGCgJWMRABSgYKAlYyEGNSCCgAKAEoAigDEkwKD1NpZGVsb2FkV2lwZW91dDgBQghEaXNhYmxlZEoNCghEaXNhYmxlZBC0AUoLCgdFbmFibGVkEBRSERILMjUuMC4xMzIxLiogACgAEk8KDUVuYWJsZVN0YWdlM0QYgIj+hgU4AUIHZW5hYmxlZEoMCgdlbmFibGVkELYHSg8KC2JsYWNrbGlzdGVkEDJSDhIEMjIuKiAAIAEgAigAElEKDUVuYWJsZVN0YWdlM0QYgIj+hgU4AUIHZW5hYmxlZEoMCgdlbmFibGVkELYHSg8KC2JsYWNrbGlzdGVkEDJSEBIEMjIuKhoEMjIuKiADKAASQQoTVGVzdDBQZXJjZW50RGVmYXVsdBiAnJKlBTgBQgdkZWZhdWx0SgsKB2RlZmF1bHQQAEoMCghncm91cF8wMRBkEu8BCh9VTUEtVW5pZm9ybWl0eS1UcmlhbC0xMC1QZXJjZW50GICckqUFOAFCB2RlZmF1bHRKEAoHZGVmYXVsdBABGJi2yQFKEQoIZ3JvdXBfMDEQARiZtskBShEKCGdyb3VwXzAyEAEYmrbJAUoRCghncm91cF8wMxABGJu2yQFKEQoIZ3JvdXBfMDQQARictskBShEKCGdyb3VwXzA1EAEYnbbJAUoRCghncm91cF8wNhABGJ62yQFKEQoIZ3JvdXBfMDcQARiftskBShEKCGdyb3VwXzA4EAEYoLbJAUoRCghncm91cF8wORABGKG2yQESnA8KHlVNQS1Vbmlmb3JtaXR5LVRyaWFsLTEtUGVyY2VudBiAnJKlBTgBQgdkZWZhdWx0ShAKB2RlZmF1bHQQARigtckBShEKCGdyb3VwXzAxEAEYobXJAUoRCghncm91cF8wMhABGKK1yQFKEQoIZ3JvdXBfMDMQARijtckBShEKCGdyb3VwXzA0EAEYpLXJAUoRCghncm91cF8wNRABGKW1yQFKEQoIZ3JvdXBfMDYQARimtckBShEKCGdyb3VwXzA3EAEYp7XJAUoRCghncm91cF8wOBABGKi1yQFKEQoIZ3JvdXBfMDkQARiptckBShEKCGdyb3VwXzEwEAEYqrXJAUoRCghncm91cF8xMRABGKu1yQFKEQoIZ3JvdXBfMTIQARistckBShEKCGdyb3VwXzEzEAEYrbXJAUoRCghncm91cF8xNBABGK61yQFKEQoIZ3JvdXBfMTUQARivtckBShEKCGdyb3VwXzE2EAEYsLXJAUoRCghncm91cF8xNxABGLG1yQFKEQoIZ3JvdXBfMTgQARiytckBShEKCGdyb3VwXzE5EAEYs7XJAUoRCghncm91cF8yMBABGLS1yQFKEQoIZ3JvdXBfMjEQARi1tckBShEKCGdyb3VwXzIyEAEYtrXJAUoRCghncm91cF8yMxABGLe1yQFKEQoIZ3JvdXBfMjQQARi4tckBShEKCGdyb3VwXzI1EAEYubXJAUoRCghncm91cF8yNhABGLq1yQFKEQoIZ3JvdXBfMjcQARi7tckBShEKCGdyb3VwXzI4EAEYvLXJAUoRCghncm91cF8yORABGL21yQFKEQoIZ3JvdXBfMzAQARi+tckBShEKCGdyb3VwXzMxEAEYv7XJAUoRCghncm91cF8zMhABGMC1yQFKEQoIZ3JvdXBfMzMQARjBtckBShEKCGdyb3VwXzM0EAEYwrXJAUoRCghncm91cF8zNRABGMO1yQFKEQoIZ3JvdXBfMzYQARjEtckBShEKCGdyb3VwXzM3EAEYxbXJAUoRCghncm91cF8zOBABGMa1yQFKEQoIZ3JvdXBfMzkQARjHtckBShEKCGdyb3VwXzQwEAEYyLXJAUoRCghncm91cF80MRABGMm1yQFKEQoIZ3JvdXBfNDIQARjKtckBShEKCGdyb3VwXzQzEAEYy7XJAUoRCghncm91cF80NBABGMy1yQFKEQoIZ3JvdXBfNDUQARjNtckBShEKCGdyb3VwXzQ2EAEYzrXJAUoRCghncm91cF80NxABGM+1yQFKEQoIZ3JvdXBfNDgQARjQtckBShEKCGdyb3VwXzQ5EAEY0bXJAUoRCghncm91cF81MBABGNK1yQFKEQoIZ3JvdXBfNTEQARjTtckBShEKCGdyb3VwXzUyEAEY1LXJAUoRCghncm91cF81MxABGNW1yQFKEQoIZ3JvdXBfNTQQARjWtckBShEKCGdyb3VwXzU1EAEY17XJAUoRCghncm91cF81NhABGNi1yQFKEQoIZ3JvdXBfNTcQARjZtckBShEKCGdyb3VwXzU4EAEY2rXJAUoRCghncm91cF81ORABGNu1yQFKEQoIZ3JvdXBfNjAQARjctckBShEKCGdyb3VwXzYxEAEY3bXJAUoRCghncm91cF82MhABGN61yQFKEQoIZ3JvdXBfNjMQARjftckBShEKCGdyb3VwXzY0EAEY4LXJAUoRCghncm91cF82NRABGOG1yQFKEQoIZ3JvdXBfNjYQARjitckBShEKCGdyb3VwXzY3EAEY47XJAUoRCghncm91cF82OBABGOS1yQFKEQoIZ3JvdXBfNjkQARjltckBShEKCGdyb3VwXzcwEAEY5rXJAUoRCghncm91cF83MRABGOe1yQFKEQoIZ3JvdXBfNzIQARjotckBShEKCGdyb3VwXzczEAEY6bXJAUoRCghncm91cF83NBABGOq1yQFKEQoIZ3JvdXBfNzUQARjrtckBShEKCGdyb3VwXzc2EAEY7LXJAUoRCghncm91cF83NxABGO21yQFKEQoIZ3JvdXBfNzgQARjutckBShEKCGdyb3VwXzc5EAEY77XJAUoRCghncm91cF84MBABGPC1yQFKEQoIZ3JvdXBfODEQARjxtckBShEKCGdyb3VwXzgyEAEY8rXJAUoRCghncm91cF84MxABGPO1yQFKEQoIZ3JvdXBfODQQARj0tckBShEKCGdyb3VwXzg1EAEY9bXJAUoRCghncm91cF84NhABGPa1yQFKEQoIZ3JvdXBfODcQARj3tckBShEKCGdyb3VwXzg4EAEY+LXJAUoRCghncm91cF84ORABGPm1yQFKEQoIZ3JvdXBfOTAQARj6tckBShEKCGdyb3VwXzkxEAEY+7XJAUoRCghncm91cF85MhABGPy1yQFKEQoIZ3JvdXBfOTMQARj9tckBShEKCGdyb3VwXzk0EAEY/rXJAUoRCghncm91cF85NRABGP+1yQFKEQoIZ3JvdXBfOTYQARiAtskBShEKCGdyb3VwXzk3EAEYgbbJAUoRCghncm91cF85OBABGIK2yQFKEQoIZ3JvdXBfOTkQARiDtskBEpABCh9VTUEtVW5pZm9ybWl0eS1UcmlhbC0yMC1QZXJjZW50GICckqUFOAFCB2RlZmF1bHRKEAoHZGVmYXVsdBABGKK2yQFKEQoIZ3JvdXBfMDEQARijtskBShEKCGdyb3VwXzAyEAEYpLbJAUoRCghncm91cF8wMxABGKW2yQFKEQoIZ3JvdXBfMDQQARimtskBElcKH1VNQS1Vbmlmb3JtaXR5LVRyaWFsLTUwLVBlcmNlbnQYgJySpQU4AUIHZGVmYXVsdEoQCgdkZWZhdWx0EAEYp7bJAUoRCghncm91cF8wMRABGKi2yQESrAMKHlVNQS1Vbmlmb3JtaXR5LVRyaWFsLTUtUGVyY2VudBiAnJKlBTgBQgdkZWZhdWx0ShAKB2RlZmF1bHQQARiEtskBShEKCGdyb3VwXzAxEAEYhbbJAUoRCghncm91cF8wMhABGIa2yQFKEQoIZ3JvdXBfMDMQARiHtskBShEKCGdyb3VwXzA0EAEYiLbJAUoRCghncm91cF8wNRABGIm2yQFKEQoIZ3JvdXBfMDYQARiKtskBShEKCGdyb3VwXzA3EAEYi7bJAUoRCghncm91cF8wOBABGIy2yQFKEQoIZ3JvdXBfMDkQARiNtskBShEKCGdyb3VwXzEwEAEYjrbJAUoRCghncm91cF8xMRABGI+2yQFKEQoIZ3JvdXBfMTIQARiQtskBShEKCGdyb3VwXzEzEAEYkbbJAUoRCghncm91cF8xNBABGJK2yQFKEQoIZ3JvdXBfMTUQARiTtskBShEKCGdyb3VwXzE2EAEYlLbJAUoRCghncm91cF8xNxABGJW2yQFKEQoIZ3JvdXBfMTgQARiWtskBShEKCGdyb3VwXzE5EAEYl7bJAQ==",
   "variations_seed_date": "12998028410000000",
   "was": {
      "restarted": false
   }
$'}'
END-OF-LOCALSTATE
}
