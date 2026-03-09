//顯示時間
(function($) {
    //取得當前網址
    function get_url(){
        var url = window.location.toString().split('?');
        return url[0];
    }
	//初始配置
    var config = {
        //標題
        'title': '編輯',
        //標題
        'html': '',
        //想放置在 dailogEnd 的HTML
        'end': '',
        //樣式
        'type': 'editor',
        'form': true,
        //dailogBg CSS
        'dailogBgColor': '#333',
        'dailogBgOpacity': 0.5,
        //dailogContainer CSS
        'dailogContainerSize': 150,
        'dailogContainerColotr': '#fff',
        //clean後 要執行 外來 func
        //'clean_extend_func':'',
        'close': '×',
    };
    var ver = 'dailog';
    var removeObj = new Array();
    //擴充 FUNC
    $.fn.extend({
        dailog: function (options) {
            //合併defaults 和 options 後面變數合併到前面變數
            $.extend(config, options);
            $(this).dailog_fill_all();
            //回傳本身JQ物件
            return $(this);
        },
        dailog_fill_all: function () {
            $('body').append('<div class="dailogBg"></div>');
            var attr = new Object();
            var XY = $.fn.dailog_range();
            attr['position'] = 'absolute';
            attr['left'] = '0px';
            attr['top'] = '0px';
            attr['background'] = config.dailogBgColor;
            attr['width'] = XY.x;
            attr['height'] = XY.y;
            attr = $(this).dailog_opacity(config.dailogBgOpacity, attr);
            $('.dailogBg').css(attr);
            $('.dailogBg').click($.fn.dailog_clean);
            removeObj.push($('.dailogBg'));
            $(this).dailog_resize();
            $.fn.dailog_produceContainer();
        },
        dailog_range: function () {
            var XY = new Object();
            if ($.fn.dailog_is_ie()) {
                XY.x = $(window).scrollLeft() + document.documentElement.clientWidth;
                XY.y = $(window).scrollTop() + document.documentElement.clientHeight;
            } else {
                XY.x = $(window).scrollLeft() + window.outerWidth;
                XY.y = $(window).scrollTop() + window.outerHeight;
            }
            if ($('body').height() > XY.y) {
                XY.y = $('body').height();
            }
            if ($('body').height() > XY.x) {
                XY.x = $('body').width();
            }
            return XY;
        },
        dailog_resize: function () {
            $(window).unbind('resize');
            $(window).resize(function () {
                var attr = {};
                var XY = $.fn.dailog_range();
                attr['width'] = XY.x;
                attr['height'] = XY.y;
                if ($('.dailogBg').size() > 0)
                    $('.dailogBg').css(attr);
            })
        },
        dailog_clean: function () {
            $(window).unbind('resize');
            if (!!removeObj) {
                for (var obj in removeObj) {
                    if (!!removeObj[obj].remove)
                        removeObj[obj].remove();
                }
                removeObj = new Array();
            }
            config.html = '';
            config.end = '';
            config.type = 'editor';
            /*
             if(!!config['clean_extend_func']){
             config['clean_extend_func']();
             }
             */
        },
        dailog_produceContainer: function () {
            $('body').append('<div class="mid"></div>');
            $('.mid').css({'position': 'absolute', 'left': '50%', 'top': '50%', 'width': '20px', 'height': '20px'});
            removeObj.push($('.mid'));
            $('.mid').append('<div class="dailogContainer"></div>');
            var cssSet = {};
            cssSet['position'] = 'relative';
            cssSet['width'] = config.dailogContainerSize;
            cssSet['height'] = config.dailogContainerSize;
            cssSet['left'] = (config.dailogContainerSize / 2 * -1) + $(window).scrollLeft() + 'px';
            cssSet['top'] = (config.dailogContainerSize / 2 * -1) + $(window).scrollTop() + 'px';
            cssSet['background'] = config.dailogContainerColotr;
            // 2022/05/04 Neil 後台資料表格對齊
            cssSet['z-index'] = 10;
            $('.dailogContainer').css(cssSet);
            if (config.form) {
                var form = document.createElement("form");
                var prop = {};
                prop['method'] = "post";
                prop['enctype'] = "multipart/form-data";
                prop['autocomplete'] = "off";
                $(form).attr(prop);
                // Added By Aber Lu at 2018/02/08 add style start
                $(form).css({'height':'100%'});
                // Added By Aber Lu at 2018/02/08 add style end
                $('.dailogContainer').append(form);
                $parent = $('.dailogContainer>form');
            } else {
                $('.dailogContainer').append(cssSet);
                $parent = $('.dailogContainer');
            }
            if (!config.title)
                config.title = '&nbsp';
            $parent.append('<div class="dailogTitle"><div>' + config.title + '<a>' + config.close + '</a>' + '</div></div>');
            $('.dailogTitle').mousedown($.fn.dailog_move);
            $('.dailogTitle').mouseup($.fn.dailog_move_stop);
            $('.dailogBg').mouseup($.fn.dailog_move_stop);
            //$parent.mouseleave($.fn.dailog_move_stop);
            $('.dailogTitle a').click($.fn.dailog_clean);
            // 2018-03-12 shang 下拉選單 頁面需求 顯示衝突修正
            var now_url = get_url();
            now_url = now_url.split('/').pop();
            if(now_url == 'sales'){
                // Modified By Aber Lu at 2018/02/08 加上style
                $parent.append('<div class="dailogContent" style="height: calc(100% - 60px) !important;width: 100%;overflow-x: hidden;overflow-y: auto;"></div>');
            }else{
                $parent.append('<div class="dailogContent"></div>');
            }
	    switch (config.type) {
                case 'editor':
                    $parent.append('<div class="dailogEnd"></div>');
                    break;
                case 'html':
                    $('.dailogContent').append(config.html);
                    $parent.append('<div class="dailogEnd"></div>');
                    break;
                case 'img':
                    $('.dailogContent').append(config.html);
                    $parent.append('<div class="dailogEnd"></div>');
                    break;
                default:
                    $parent.append(config.html);
                    break;
            }
            $.fn.dailog_end();
        },
        dailog_end: function () {
            if ($('.dailogEnd').length == 1 && !!config.end) {
                $('.dailogEnd').append(config.end);
            }
        },
        dailog_show: function () {
            switch (config.type) {
                case 'editor':
                    $(this).dailog_editor();
                    break;
                case 'html':
                    $(this).dailog_html();
                    break;
                case 'img':
                    $(this).dailog_image();
                    break;
                default:
                    $(this).dailog_html();
                    break;
            }
            return $(this);
        },
        dailog_html: function () {
            var obj = $('.dailogContent').children();
            if (obj.length > 0) {
                var width = obj.eq(0).width();
                var height = 0;
                obj.each(function () {
                    height += $(this).height();
                });
                height += 16
                $.fn.dailog_start_action(width, height);
            }
        },
        dailog_image: function () {
            var obj = $('.dailogContent').children();
            if (obj.length > 0) {
                var width = 0;
                var height = 0;
                obj.each(function () {
                    height += $(this).height();
                });
                $('.dailogContent img').each(function () {
                    if ($(this).width() > width)
                        width = $(this).width();
                });
                height += 16
                $.fn.dailog_start_action(width, height);
            }
        },
        dailog_editor: function () {
            var js = document.createElement("script");
            var prop = {};
            prop['id'] = "editor";
            prop['type'] = "text/plain";
            prop['name'] = $(this).attr('name');
            $(js).attr(prop);
            //還要放 form 標籤 (暫時未放)
            $('.dailogContent').append(js);
            var value = $(this).children().length == 1 ? $(this).children().html() : '';
            var edit = new UE.ui.Editor();
            edit.render("editor");
            edit.ready(function () {
                var height = edit.options.initialFrameHeight;
                var width = edit.options.initialFrameWidth;
                height = height + 45;
                $.fn.dailog_start_action(width, height);
                edit.setContent(value);
            })
        },
        dailog_start_action: function (w, h) {
            if (!!w && !!h) {
                $('.dailogContainer').animate({
                    'left': (w / 2 * -1) + $(window).scrollLeft(),
                    'top': ( ( h + $('.dailogTitle').height() + $('.dailogEnd').height() ) / 2 * -1) + $(window).scrollTop(),
                    'width': w,
                    //40 是 $('.dailogTitle') 的 height
                    'height': h + $('.dailogTitle').height() + $('.dailogEnd').height()
                }, 500);
            }
        },
        dailog_move: function (e) {
            var initM = {};
            initM.x = e.clientX;
            initM.y = e.clientY;
            var conPos = $('.dailogContainer').position();
            var dailog_move_func = function (event) {
                var pos = {};
                pos.x = event.clientX;
                pos.y = event.clientY;
                var dis = {};
                dis.x = pos.x - initM.x;
                dis.y = pos.y - initM.y;
                $('.dailogContainer').css({
                    'left': conPos.left + dis.x,
                    'top': conPos.top + dis.y,
                })
            }
            $(document).bind('mousemove', dailog_move_func);
        },
        dailog_move_stop: function (e) {
            $(document).unbind('mousemove');
        },
        dailog_opacity: function (opacity, obj) {
            if (!!opacity) {
                if (!!obj) {
                    if ($.fn.dailog_is_ie()) {
                        obj.filter = 'alpha(opacity=' + opacity * 100 + ')';
                    } else {
                        obj.opacity = opacity;
                    }
                    return obj;
                }
            }
        },
        dailog_is_ie: function () {
            var isIE = navigator.userAgent.search("MSIE") > -1;
            return isIE;
        }
    });
}(jQuery));