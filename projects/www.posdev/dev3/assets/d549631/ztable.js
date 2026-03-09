// 2023/06/29 Added By Neil 加上 Loader
const loading = {
    width: '320px',
    height: '150px',
    top: '32%',
    zIndex: 100000,
    set: function (width = '320px', height = '150px', top = '32%', zIndex = 100000) {
        this.width = width;
        this.height = height;
        this.top = top;
        this.zIndex = zIndex;
    },
    /**
     * 顯示 loading
     * @param text
     */
    show(text = '任務執行中') {
        if (!! $?.blockUI) {
            let message = '<div class="loader loader--glisteningWindow"></div><p><div><h1>' + text + '...</h1></div>';
            $.blockUI({message: message, css: {width: this.width, height: this.height, top: this.top, zIndex:this.zIndex}});
        }
    },
    /** 隱藏 loading */
    hide() {
        if (!! $?.blockUI) {
            $.unblockUI();
        }
    }
};

// 2024/09/26 [匯入檔案] By Neil Added 匯入按鈕，點擊後必須要有 loading 避免使用者，重覆點擊
const dialogUploader = {
    validateForm(form) {
        const fileInput = form.querySelector('input[type="file"]').value;

        if (fileInput === "") {
            z_alert("請先選擇檔案。");
            return false;
        }

        loading.show('上傳中');
        this.disableSubmitButton(form);
        return true;
    },
    disableSubmitButton(form) {
        const submitBtn = form.querySelector('input[type="submit"]');
        submitBtn.disabled = true;
        submitBtn.value = '上傳中...';
    }
};

// Added By Aber Lu at 2018/02/08 將 show 與 hide 加入event trigger start
(function ($) {
    $.each(['show', 'hide'], function (i, ev) {
        var el = $.fn[ev];
        $.fn[ev] = function () {
            this.trigger(ev);
            return el.apply(this, arguments);
        };
    });
})(jQuery);
// Added By Aber Lu at 2018/02/08 將 show 與 hide 加入event trigger end

// JavaScript Document
function get_url() {
    var url = window.location.toString();
    return url;
}
function multipleSelect() {
    // 2025/12/12 [後台資料表格對齊] Neil 修正 selector
    recordTable.rows().click("keydown", function (e) {
        if (e.ctrlKey) {
            if (select.hasClass("row_selected")) {
                select.removeClass("row_selected");
            } else {
                select.addClass("row_selected");
            }
            lastSelect = $(this);
        } else if (e.shiftKey) {
            if (lastSelect == null) {
                select.addClass("row_selected");
            } else {
                first = lastSelect.attr('id');
                // 2025/12/12 [後台資料表格對齊] Neil
                recordTable.selectedRows().each(function () {
                    $(this).removeClass("row_selected");
                });
                var s = true;
                var inside = false;
                // 2025/12/12 [後台資料表格對齊] Neil
                recordTable.each(function (index) {
                    if ((first == $(this).attr('id') || select.attr('id') == $(this).attr('id')) && s) {
                        $(this).addClass("row_selected");
                        s = false;
                        inside = true;
                    } else {
                        if ((first == $(this).attr('id') || select.attr('id') == $(this).attr('id'))) {
                            $(this).addClass("row_selected");
                            inside = false;
                        } else if (inside) {
                            $(this).addClass("row_selected");
                        }
                    }
                });
            }
        } else {
            // 2025/12/12 [後台資料表格對齊] Neil
            recordTable.selectedRows().removeClass("row_selected");
            recordTable.newRows().remove();
            // 2025/12/12 [後台資料表格對齊] Neil 移除重複 removeClass 片段
            $(this).addClass("row_selected");
            lastSelect = $(this);
        }
    });
}

var Options = function (obj) {
    var self = this;
    self.id = obj.id;
    self.width = obj.width;
    self.type = obj.type;
    self.data = obj.option;
    self.insert = obj.insert;
    self.need = obj.need;
    self.defaultValue = obj.defaultValue;
    self.getText = function (val) {
        return self.data[val];
    }
    self.getValue = function (text) {
        for (var key in self.data) {
            if (self.data[key] === text) {
                return key;
            }
        }
        return false;
    }
    self.getHtmlObj = function (val) {
        var html = $('<select>');
        // 2023/10/03 Added By Neil 排序
        Object.keys(self.data).sort().forEach(key => {
            var opt = $('<option>').attr("value", key).html(self.data[key]);
            if (val == self.data[key]) {
                opt.attr("selected", "selected");
            }
            html.append(opt);
        });

        /*for (var key in self.data) {
            if (typeof self.data[key] === "string") {
                var opt = $('<option>').attr("value", key).html(self.data[key]);
                if (val == self.data[key]) {
                    opt.attr("selected", "selected");
                }
                html.append(opt);
            }
        }*/
        return html;
    }
    //2019-09-09 shang 修正 帶入顧客後未設價別之後續顯示 start 【06-06】
    self.getOption3 = function(val){
        var page_name = getPageName();
        var html = $('<select>');
        for (var key in self.data) {
            if (typeof self.data[key] === "string") {
                if((page_name == "maintain/items")){
                    var opt = $('<option>').attr("value", key).html(self.data[key]);
                    if ("應稅" == self.data[key]) {
                        opt.attr("selected", "selected");
                    }
                    html.append(opt);
                }else{
                    if(key != 0){
                        var opt = $('<option>').attr("value", key).html(self.data[key]);
                        if (val == self.data[key]) {
                            opt.attr("selected", "selected");
                        }
                        html.append(opt);
                    }
                }
            }
        }
        return html;
    }
    //2019-09-09 shang 修正 帶入顧客後未設價別之後續顯示 end 【06-06】
}
var editBolean = function () {
    var self = this;
    // 2024/05/06 Add By Neil [商品群組限量]原值
    const dom = self.td.children('input').get(0);
    const origin = !dom.checked;
    var val = dom.checked ? 1 : 0;
    self.update(val);
    dom.checked = origin;
}
// Added Callback by Aber Lu at 2017/08/23 start
var editOption = function (callback = null) {
    var self = this;
    var input = self.option.getHtmlObj(this.value);
    // 2024/01/23 Modified By Neil [歐客佬]會員作業登錄
    const width = (self.td.width() - 20) + 'px';
    input.css({'width': width}).mousedown(function (e) {
        e.stopPropagation()
    }).blur(function (e) {
        self.td.html(self.value);
        self.id = 0;
    }).change(function (e) {
        self.update($(this).val());
    });
    self.td.html(input);
    input.focus();
    // Modified By Aber Lu at 2017/08/22 start
    if (callback !== null) {
        return callback();
    }
    // Modified By Aber Lu at 2017/08/22 end
};
// Added Callback by Aber Lu at 2017/08/23 end
var editOption2 = function (obj = this, val = this.value) {
    var self = obj;
    var input = self.option.getHtmlObj(val);
    // 2024/05/06 Add By Neil [商品群組限量]option2 原值
    const origin = input.val();
    self.td.html(input);
    input.width(200).select2().on('close', function (e) {
        self.update(input.val());
        // 2024/05/06 Add By Neil [商品群組限量]option2 更新前先設原值，更新成功後才設新值
        self.td.html(self.option.getText(origin));
        self.id = 0;
    });
    input.select2('open');
}

// Added Callback by Aber Lu at 2017/08/22
var editText = function (callback = null) {
    var self = this;
    // 2024/01/23 Modified By Neil [歐客佬]會員作業登錄(註解未使用的 next)
    // next = new Column($('#' + $(self).attr('id')).next());
    var input = $("<input>").val(self.value).attr("type", "text").css({"width": "95%"}).blur(function (e) {
        self.td.html(self.value);
        self.id = 0;
    }).keydown(function (e) {
        if (e.which == 13) {
            // Modified By Aber Lu at 2017/08/22 start
            if (self.type !== "convert") {
                self.update(this.value);
            }
            // Modified By Aber Lu at 2017/08/22 end
        } else if (e.which == 9) {

        }
    });
    // 20231121 Vin 避免 input 重複放入, 會導致 input中產生另value文字 <input type="text" style="width: 95%;"> 
    var inputElement = self.td.find('input');
    if (inputElement.length === 0) {
        self.td.html(input);
        input.select();
        input.focus();
    }

    // Modified By Aber Lu at 2017/08/22 start
    if (callback !== null) {
        return callback();
    }
    // Modified By Aber Lu at 2017/08/22 end
}

// Added By Aber Lu at 2020/06/09 加上 password input start
var editPassword = function (callback = null) {
    var self = this;
    // 2024/01/23 Modified By Neil [歐客佬]會員作業登錄(註解未使用的 next)
    // next = new Column($('#' + $(self).attr('id')).next());
    var input = $("<input>").val(self.value).attr("type", "password").css({"width": "95%"}).blur(function (e) {
        self.td.html(self.value);
        self.id = 0;
    }).keydown(function (e) {
        if (e.which == 13) {
            if (self.type !== "convert") {
                self.update(this.value);
            }
        } else if (e.which == 9) {

        }
    });
    self.td.html(input);
    input.select();
    input.focus();
}
// Added By Aber Lu at 2020/06/09 加上 password input start

// Added By Aber Lu at 2019/12/12 加入 input type = number
var editNumber = function (callback = null) {
    var self = this;
    // 2024/01/23 Modified By Neil [歐客佬]會員作業登錄(註解未使用的 next)
    // next = new Column($('#' + $(self).attr('id')).next());
    var input = $("<input>").val(self.value).attr("type", "number").css({"width": "90%"}).blur(function (e) {
        self.td.html(self.value);
        self.id = 0;
    }).keydown(function (e) {
        if (e.which == 13) {
            // Modified By Aber Lu at 2017/08/22 start
            if (self.type !== "convert") {
                self.update(this.value);
            }
            // Modified By Aber Lu at 2017/08/22 end
        } else if (e.which == 9) {

        }
    });
	
	if (typeof self.min !== typeof undefined) {
		input.attr('min', self.min);
	}
	
	if (typeof self.max !== typeof undefined) {
		input.attr('max', self.max);
	}
	
    self.td.html(input);
    input.select();
    input.focus();

    // Modified By Aber Lu at 2017/08/22 start
    if (callback !== null) {
        return callback();
    }
    // Modified By Aber Lu at 2017/08/22 end
}

var editDate = function () {
    var self = this;
    var input = $('<input>').attr('type', 'text').val(self.value).css("width", (self.td.width() - 10) + 'px').datepicker({
        dateFormat: "yy-mm-dd",
        dayNamesMin: ["日", "一", "二", "三", "四", "五", "六"],
        monthNames: ["一月", "二月", "三月", "四月", "五月", "六月", "七月", "八月", "九月", "十月", "十一月", "十二月"],
        monthNamesShort: ["一月", "二月", "三月", "四月", "五月", "六月", "七月", "八月", "九月", "十月", "十一月", "十二月"],
        changeYear: true,
        changeMonth: true,
        yearRange: 'c-100:c+5',
        onSelect: function (dateText, ui) {
            self.update(dateText);
            self.id = 0;
        },
        onClose: function (dateText, ui) {
            self.td.html(self.value);
            self.id = 0;
        }
    });
    self.td.html(input);
    input.focus();
}

// Added By Neil at 2021/05/27 新增時掛載日期元件
var mountDate = function (el) {
    $(el).datepicker({
        dateFormat: "yy-mm-dd",
        dayNamesMin: ["日", "一", "二", "三", "四", "五", "六"],
        monthNames: ["一月", "二月", "三月", "四月", "五月", "六月", "七月", "八月", "九月", "十月", "十一月", "十二月"],
        monthNamesShort: ["一月", "二月", "三月", "四月", "五月", "六月", "七月", "八月", "九月", "十月", "十一月", "十二月"],
        changeYear: true,
        changeMonth: true,
        yearRange: 'c-100:c+5',
    });
}

var editDateTime = function () {
    var self = this;
	/* Modified By Aber Lu at 2018/07/05 修正使用方式 start */
	// 不能使用 td.width(), 要使用我們當出所賦予的width, 值藏在 column obj.option.width 下, 但該值為字串且後面帶'px', 所以需要 parseInt強制轉換
    //var input = $('<input>').attr('type', 'text').val(self.value).css("width", (self.td.width() - 10) + 'px').datetimepicker({
	var input = $('<input>').attr('type', 'text').val(self.value).css("width", (parseInt(self.option.width) - 10) + 'px').datetimepicker({
	/* Modified By Aber Lu at 2018/07/05 修正使用方式 end */
        dayNamesMin: ["日", "一", "二", "三", "四", "五", "六"],
        monthNames: ["一月", "二月", "三月", "四月", "五月", "六月", "七月", "八月", "九月", "十月", "十一月", "十二月"],
        monthNamesShort: ["一月", "二月", "三月", "四月", "五月", "六月", "七月", "八月", "九月", "十月", "十一月", "十二月"],
        changeYear: true,
        changeMonth: true,
        yearRange: 'c-100:c+5',
        timeText: '時間',
        hourText: '時',
        minuteText: '分',
        currentText: '目前時間',
        dateFormat: 'yy-mm-dd',
        timeFormat: 'hh:mm',
        closeText: '確定',
        onSelect: function (dateText, ui) {
			/* Modified By Aber Lu at 2018/07/05 修正使用方式 start */
			// 僅更新ui上的值
			$(ui).attr('value', dateText);
			// 不該直接跑去叫update
            //self.update(dateText);
            //self.id = 0;
			/* Modified By Aber Lu at 2018/07/05 修正使用方式 end */
        },
        onClose: function (dateText, ui) {
			/* Modified By Aber Lu at 2018/07/05 修正使用方式 start */
			// 不用更新畫面上的值, 因為onSelect的時候更新過了
            //self.td.html(dateText);
			// 去更薪資料庫的值
			if (typeof dateText !== typeof undefined &&
				dateText.length > 0) {
				self.update(dateText, function() {
					zTable.goPage();
				});
			}
            self.id = 0;
			/* Modified By Aber Lu at 2018/07/05 修正使用方式 end */
        }
    });
    self.td.html(input);
    input.focus();
}

// Added By Aber Lu at 2018/11/23 增加Data type Time
var editTime = function () {
    /*var self = this;
	var input = $('<input>').attr('type', 'time').val(self.value).css("width", (parseInt(self.option.width) - 10) + 'px');
    self.td.html(input).blur(function (e) {
		console.log(self.value);
        self.td.html(self.value);
        self.id = 0;
		//self.update(this.value);
    });
	input.select();
    input.focus();*/

    var self = this;
    // 2024/01/23 Modified By Neil [歐客佬]會員作業登錄(註解未使用的 next)
    // next = new Column($('#' + $(self).attr('id')).next());
    var input = $("<input>").val(self.value).attr("type", "time").css({"width": "95%"}).blur(function (e) {
        self.td.html(self.value);
        self.id = 0;
    }).keydown(function (e) {
        if (e.which == 13) {
            // Modified By Aber Lu at 2017/08/22 start
            if (self.type !== "convert") {
                self.update(this.value);
            }
            // Modified By Aber Lu at 2017/08/22 end
        } else if (e.which == 9) {

        }
    });
    self.td.html(input);
    input.select();
    input.focus();
}

var editImage = function () {
    var self = this;
    if (isset(self.option.data.width) || isset(self.option.data.height)) {
        img_alert(self.td.find("a").data("img"), {
            'update': self.name,
            'row': self.row,
            'td': self.td.attr("id")
        }, true, self.option.data);
    } else {
        img_alert(self.td.find("a").data("img"), {
            'update': self.name,
            'row': self.row,
            'td': self.td.attr("id")
        }, true);
    }
    self.id = 0;
}
var editImage2 = function () {
    var self = this;
    if (isset(self.option.data.width) || isset(self.option.data.height)) {
        img_alert(self.td.find("a").data("img"), {
            'update': self.name,
            'row': self.row,
            'td': self.td.attr("id")
        }, true, self.option.data);
    } else {
        img_alert(self.td.find("a").data("img"), {
            'update': self.name,
            'row': self.row,
            'td': self.td.attr("id")
        }, true);
    }
    self.id = 0;
}

/* Added By Aber Lu at 2018/08/08 新增Image顯示視窗 start */
// Modified By Aber Lu at 2018/10/09 新增一個旋轉度數參數, 預設為0
var showImage = function (obj, rotate = 0) {
    img_alert($(obj).data("img"), {
        'update': $(obj).parents("td").eq(0).attr("name"),
        'row': $(obj).parents("tr").eq(0).attr("id"),
        'td': $(obj).parents("td").eq(0).attr("id")
    }, false, {
        'rotate': rotate
    });
};
/* Added By Aber Lu at 2018/08/08 新增Image顯示視窗 end */
var editCkedit = function () {
    var self = this;
    ck_alert(self.td.find("a").data("content"), {'update': self.name, 'row': self.row, 'td': self.td.attr("id")}, true);
    self.id = 0;
}
var editCheck = function () {
    var self = this;
    if (self.td.find("button").length === 1) {
        var bt = self.td.find("button");
        var step = bt.data('id').step;
        var pre_step = $("#" + self.row).find("button.step" + (step - 1));
        if (pre_step.length > 0) {
            z_alert("請先完成" + pre_step.data("id").name);
        } else {
            self.id = 0;
            z_confirm("您確定要記錄" + bt.data('id').name + "時間？", function () {
                var d = new Date();
                var dateText = sprintf("%04d-%02d-%02d %02d:%02d:%02d", d.getFullYear(), (d.getMonth() + 1), d.getDate(), d.getHours(), d.getMinutes(), d.getSeconds());
                self.update(dateText);
            });
        }
    }
}
//--------- new --------
var uniqueCkedit = function () {
    /*
     var self = this;
     next = new Column( $('#'+$(self).attr('id')).next() );

     var input = $("<input>").val(self.value).attr("type","text").css({"width":"95%"}).blur(function(e) {
     self.td.html(self.value);
     self.id=0;
     }).keydown(function(e) {
     if(e.which == 13){
     //self.update(this.value);
     self.updateUnique(this.value);
     }else if(e.which == 9){}
     });
     self.td.html(input);
     //input.select();
     input.focus();
     */
}
//----------------------

var Column = function (obj) {
    var self = this;
    self.td = obj || [];
    self.id = 0;
    self.fGetColumnName = function(index) {
        //var th = $('#zdn_thead').find('th').eq(index);
        var th = $('#ztb_'+index);
        return th.text();
    }
    if (isset(obj)) {
        self.id = obj.attr('id');
        self.type = obj.attr('type');
        self.canEdit = obj.hasClass('edit_td');
        self.forInsert = obj.hasClass('for_insert');
        self.row = obj.parent('tr').attr('id');
        self.name = obj.attr('name');
        self.index = obj.attr('name').replace("td_", "");
        self.value = obj.html();
        self.option = zTable.option[self.index];
		// Added By Aber Lu at 2019/12/12 加上 min 與 max start
		if (typeof obj.attr('min') !== typeof undefined) {
			self.min = parseInt(obj.attr('min'));
		}
		if (typeof obj.attr('max') !== typeof undefined) {
			self.max = parseInt(obj.attr('max'));
		}
		// Added By Aber Lu at 2019/12/12 加上 min 與 max end
        // add callback function By Aber Lu at 2017/08/23
        self.update = function (val, callback = null) {
            if (self.canEdit) {
                var sColumnName = self.fGetColumnName(self.index);
                $.post(get_url(), {'update': self.name, 'row': self.row, 'value': val},
                    function (data) {
                        // Modified By Aber Lu at 2018/04/16 如果傳回來的是json string start
                        // 2024/05/06 Modified By Neil [商品群組限量]處理 parseJSON 異常
                        let json = null;
                        try {json = $.parseJSON(data);} catch (e) {json = data;}
						try {
                            if (typeof json === "object" && json) {
                                if (isset(json["success"]) &&
                                    !json["success"]) {
                                    if (isset(json["message"])) {
                                        z_alert(json["message"]);
                                    } else {
                                        z_alert("資料寫入失敗");
                                    }
                                    return;
                                }
                                var oRow = $("#" + self.row);
                                async.eachOfSeries(json, function(value, key, doneOfEach) {
                                    oRow.find("td[name=td_" + key + "]").html(value);
                                    return doneOfEach(null);
                                }, function(err) {
                                });
                            } else {
                                // 2024/05/06 Modified By Neil [商品群組限量]使用 switch 重構
                                switch (true) {
                                    case self.type == 'option2':// 2024/05/06 Add By Neil [商品群組限量]更新成功後才設新值
                                        self.td.html(self.option.getText(val));
                                        break;
                                    case data == 'reload' || self.type == 'password':
                                        location.reload();
                                        break;
                                    case data !== 'err' && self.type !== 'boolean':
                                        self.td.html(data);
                                        break;
                                    case self.type !== 'boolean':
                                        self.td.html(self.value);
                                        break;
                                    case self.type == 'boolean':
                                        self.td.children('input').get(0).checked = !!val;
                                        break;
                                }
	                            self.id = 0;
							}
						} catch(e) {
	                            if (self.type == 'option2') {
	                            } else if (data == 'reload' || self.type == 'password') { // Added By Aber Lu at 2020/06/09 加上password type 更新頁面
	                                location.reload();
	                            } else if (data !== 'err' && self.type !== 'boolean') {
	                                //console.log(data);
	                                self.td.html(data);
	                            } else if (self.type !== 'boolean') {
	                                self.td.html(self.value);
	                            }
	                            self.id = 0;
						}
								// Modified By Aber Lu at 2018/04/16 如果傳回來的是json string end
					}).fail(function(a,b,c) {
						console.log(a, b, c);
					}).done(function() {
						if (callback !== null) {
							return callback();
						}
					}
				);
            }
        }
        }
        /* //--------new------
         self.updateUnique = function(val){
         $.post(get_url(),
         {'update':self.name,'row':self.row,'value':val},
         function(data){
         if(data !== 'err' && self.type !== 'boolean'){
         self.td.html(data);
         }else if( self.type !== 'boolean'){
         self.td.html(self.value);
         }
         self.id = 0;
         });
         }
         */
        // Added By Aber Lu at 2017/08/22 add callback
        self.edit = function (callback = null) {
            if (self.canEdit) {
                //if( self.canEdit ||  self.type=='unique'){
                switch (self.type) {
                    case 'check':
                        editCheck.call(self);
                        break;
                    // Added By Aber Lu at 2020/06/09 加上password 欄位 start
                    case 'password':
                        editPassword.call(self);
                        break;
                    // Added By Aber Lu at 2020/06/09 加上password 欄位 end
                    case 'option':
                        // Added By Aber Lu at 2017/08/22 add callback start
                        if (callback !== null) {
                            editOption.call(self, callback);
                        } else {
                            editOption.call(self);
                        }
                        // Added By Aber Lu at 2017/08/22 add callback end
                        break;
                    case 'option2':
                        editOption2.call(self);
                        break;
                    case 'boolean':
                        editBolean.call(self);
                        break;
                    case 'date':
                        editDate.call(self);
                        break;
					// Added at 2018/11/23 By Aber Lu 增加 datatype = time
                    case 'time':
                        editTime.call(self);
                        break;
                    case 'image':
                    case 'image3':
                        editImage.call(self);
                        break;
                    case 'ckedit':
                        editCkedit.call(self);
                        break;
                    case 'datetime':
                        editDateTime.call(self);
                        break;
                    case 'button':
                    case 'chkfunc':
                        break;
					// Added By Aber Lu at 2019/12/12 加入 int start
					case 'int':
						// call init input type = number
                        if (callback !== null) {
                            editNumber.call(self, callback);
                        } else {
							editNumber.call(self);
                        }
						break;
					// Added By Aber Lu at 2019/12/12 加入 int end
					
                    //------ new --------
                    /*
                     case 'unique':
                     uniqueCkedit.call(self);
                     break;
                     */
                    //------ new ------
                    default:
                        // Added By Aber Lu at 2017/08/22 add callback start
                        if (callback !== null) {
                            editText.call(self, callback);
                        } else {
                            editText.call(self);
                        }
                        // Added By Aber Lu at 2017/08/22 add callback end
                }
            } else if (self.type === "image") {
                if (isset(self.option.data.width) || isset(self.option.data.height)) {
                    img_alert(self.td.find("a").data("img"), null, false, self.option.data);
                } else {
                    img_alert(self.td.find("a").data("img"));
                }
                self.id = 0;
            } else if (self.type === "image2") {
                if (isset(self.option.data.width) || isset(self.option.data.height)) {
                    img_alert(self.td.find("a").data("img"), null, false, self.option.data);
                } else {
                    self.option.data.width = 500;
                    img_alert(self.td.find("a").data("img"), null, false, self.option.data);
                }
                self.id = 0;

            } else if (self.type === "ckedit") {
                ck_alert(self.td.find("a").data("content"));
                self.id = 0;
            }
        }
    }

var lastSelect = null;

var zTable = {
    // 2022/05/04 Neil 後台資料表格對齊
    isTableAlignment: false,
    // 2022/05/04 [後台資料表格對齊] Neil 列印功能提取
    printTemplate: '',// 在 script.php 會設置
    print: {// goPage 列印功能提取至 zTable.print
        template: null,
        decorate: null,// 裝飾 template，例： (template) => template.replace('{head}',title)
        exec: function() {
            var PrintObj = window.open('', 'printWindow', 'toolbar=yes,status=yes,menubar=yes,scrollbars=yes,copyhistory=no,resizable=yes');
            var docu = PrintObj.document;
            var $body = $('body', docu);
            var template = this.template ?? zTable.printTemplate;
            var $tableHtml = $('<div>');
            // 2022/05/04 Modified By Neil 後台資料表格對齊，已移除 #zdn_thead 內容
            if (!zTable.isTableAlignment) {
                $('table', $('#zdn_thead')).each(function () {
                    $tableHtml.append($(this).clone());
                })
            }

            $('table', $('#zdn_tbody')).each(function () {
                $tableHtml.append($(this).clone());
            })
            template = template.replace('{table}', $tableHtml.html());
            // 2022/05/04 [後台資料表格對齊] Neiltemplate replace 處理
            if (_.isFunction(this.decorate)) {
                template = this.decorate(template);
            }
            $body.append(template);
            PrintObj.print();
            PrintObj.close();
        }
    },
    // 2022/05/04 [後台資料表格對齊] Neil 頁面渲染 Hook
    hooks: {
        page: {
            before: null,//渲染前
            after: null,// 渲染後
        },
    },
    afterDelete: null,
    /**
     * 表格元素選擇器 // 2025/12/12 [後台資料表格對齊] Neil
     * @returns {{thead: string, body: string, row: string, selectedRow: string, newRow: string}}
     */
    selector: function () {
        return recordTable.selector;
    },
    /**
     * tbody 元素 // 2025/12/12 [後台資料表格對齊] Neil
     * @returns {*|Window.jQuery|HTMLElement}
     */
    body: function () {
      return recordTable.body();
    },
    /**
     * 表格 tr 元素集合 // 2025/12/12 [後台資料表格對齊] Neil
     * @returns {*|Window.jQuery|HTMLElement}
     */
    rows: function () {
        return recordTable.rows()
    },
    /**
     * 有新列 // 2025/12/12 [後台資料表格對齊] Neil
     * @returns {boolean}
     */
    hasNewRows: function () {
        return !!this.newRows().length;
    },
    /**
     * 表格新列 // 2025/12/12 [後台資料表格對齊] Neil
     * @returns {*|Window.jQuery|HTMLElement}
     */
    newRows: function () {
        return recordTable.newRows();
    },
    /**
     * 表格 tr 元素 each // 2025/12/12 [後台資料表格對齊] Neil
     * @param fn
     */
    each: function (fn) {
        recordTable.each(fn);
    },
    'buffer': {'seacher': {}, 'order': '', 'offset': 0, 'column': new Column(), 'hidden': []},
    'option': [],
    'setOption': function (obj) {
        for (var i = 0; i < obj.length; i++) {
            this.option.push(new Options(obj[i]));
        }
    },
    'toggleSearchBar': function () {
        var bt = $(".ztable_toggle_bt");
        if (bt.text() === "+") {
            bt.text("－").css("font-size", "1em");
            $("#zdn_search_form").css("overflow", "visible");
        } else {
            bt.text("+").css("font-size", "2em");
            $("#zdn_search_form").css("overflow", "hidden");
        }
    },
    'fix': function () {
        // 2022/05/04 Neil 後台資料表格對齊，修正 zdn_tbody 的 max-height
        if (this.isTableAlignment) {
            let excludHeight = $('body').width() >= 1080 ? 0 : $('footer').height();
            ['#setting_panel', '#zdn_controller', '#zdn_thead', '#zdn_tfoot'].forEach((selector) => {
                excludHeight += $(selector).outerHeight(true);
            });

            $(".zdn_tbody").css("max-height", $('#content').height() - excludHeight);
            $("#zdn_tbody").css({'overflow-y': 'auto'});
            return;
        }

        var content_h = $("#content").height();
        var tbody_h = $("#zdn_tbody").height();
        var other_h = $("#zdn_controller").height() + $("#zdn_thead").height() + $("#zdn_tfoot").height();
        if ((tbody_h + other_h + 50) > content_h) {
            // 2024/01/23 Modified By Neil [歐客佬]
            $("#zdn_tbody").css("max-height", (content_h - other_h - 50) + 'px');
            //$("#zdn_tbody").niceScroll();
            $("#zdn_tbody").css({'overflow-y': 'auto'});
        }
    },
    'hidden': function () {
        var arr = this.buffer.hidden;
        for (i = 0; i < arr.length; i++) {
            // 2022/05/04 Modified By Neil 後台資料表格對齊
            if (this.isTableAlignment) {
                $("#zdn_tbody th").eq(arr[i]).addClass('td_hidden');
                // 2022/05/04 [後台資料表格對齊] Neil 原本的 #zdn_thead 也保留，在列印或其他功能會用到，所以也要加 td_hidden class
                $("#zdn_thead th").eq(arr[i]).addClass('td_hidden');
            } else {
                $("#zdn_thead th").eq(arr[i]).addClass('td_hidden');
            }
            // 2025/12/12 [後台資料表格對齊] Neil 修正 selector
            this.each(function (index, element) {
                $(this).children('td').eq(arr[i]).addClass('td_hidden');
            });
        }
    },
    'thSelect': function (th, id) {
        if ($(th).hasClass("column_selected")) {
            // 2022/05/04 Modified By Neil 後台資料表格對齊
            if (this.isTableAlignment) {
                $("#zdn_tbody th.column_selected,#zdn_tbody td.column_selected").removeClass("column_selected");
            } else {
                $("#zdn_thead th.column_selected,#zdn_tbody td.column_selected").removeClass("column_selected");
            }
        } else {
            // 2022/05/04 Modified By Neil 後台資料表格對齊
            if (this.isTableAlignment) {
                $("#zdn_tbody th.column_selected,#zdn_tbody td.column_selected").removeClass("column_selected");
            } else {
                $("#zdn_thead th.column_selected,#zdn_tbody td.column_selected").removeClass("column_selected");
            }
            $(th).addClass("column_selected");
            // 2025/12/12 [後台資料表格對齊] Neil 修正 selector
            this.each(function (index, element) {
                $(this).children("td").eq(id).addClass("column_selected");
            });
        }
    },
    'rowSelect': function (row) {
        /*shift ctrl select*/
        // 2025/12/12 [後台資料表格對齊] Neil 修正 selector
        this.newRows().remove();
        select = $(row);
    },
    'loading': function () {
        var cover = $("<div>").width($("#zdn_tbody").width()).height($("#zdn_tbody").height()).css({
            'position': 'absolute',
            'z-index': 'auto',
            'background-color': 'rgba(120,120,120,0.5)'
        }).append('<table style="height:100%;width:100%;"><tr><td align="center" valign="middle"><center><div class="loading">檔案讀取中</div></center></td></tr></table>');
        $("#zdn_tbody").prepend(cover);
    },
    'show': function () {
        $("div.zdn_columns").css('margin-left', ($("div.zdn_columns").width() * -1 + 60) + 'px');
        $("div.zdn_columns").toggle('fast');
    },
    'toggleColumn': function (obj) {
        var x = obj.value;
        if (obj.checked) {
            // 2022/05/04 Modified By Neil 後台資料表格對齊
            if (this.isTableAlignment) {
                $("#zdn_tbody th").eq(x).removeClass('td_hidden');
            } else {
                $("#zdn_thead th").eq(x).removeClass('td_hidden');
            }

            // 2025/12/12 [後台資料表格對齊] Neil 修正 selector
            this.each(function (index, element) {
                $(this).children('td').eq(x).removeClass('td_hidden');
            });
            $.post(get_url(), {'action': 'check', 'hidden': x}, function (data) {
                console.log(data);
            });
            zTable.buffer.hidden.splice(zTable.buffer.hidden.indexOf(obj.value), 1);
        } else {
            // 2022/05/04 Modified By Neil 後台資料表格對齊
            if (this.isTableAlignment) {
                $("#zdn_tbody th").eq(x).addClass('td_hidden');
            } else {
                $("#zdn_thead th").eq(x).addClass('td_hidden');
            }

            // 2025/12/12 [後台資料表格對齊] Neil 修正 selector
            this.each(function (index, element) {
                $(this).children('td').eq(x).addClass('td_hidden');
            });
            $.post(get_url(), {'action': 'uncheck', 'hidden': x}, function (data) {
                console.log(data);
            });
            zTable.buffer.hidden.push(x);
        }
        // 2022/05/04 Neil 後台資料表格對齊，當欄位對齊選項存在時，重置固定欄位
        if (!!$('.zdn-sticky-panel').length) {
            document.body.dispatchEvent(new Event('RefreshZdnfreezeColumn'));
        }
    },
    'order': function (str) {
        // 2022/05/04 Modified By Neil 後台資料表格對齊
        if (this.isTableAlignment) {
            var column = $("#zdn_tbody th.column_selected");
        } else {
            var column = $("#zdn_thead th.column_selected");
        }

        if (column.length === 1) {
            this.buffer.order = column.attr('id') + ':' + str;
            this.goPage(this.buffer.offset);
        } else {
            z_alert("您尚未選取任何欄位");
        }
    },
    // Added Callback  function By Aber Lu at 2017/08/22 start
    'edit': function (td, callback = null) {
        if (td.id != this.buffer.column.id) {
            this.buffer.column = new Column($(td));
            // Added By Aber Lu at 2017/08/22 for callback function start
            if (callback !== null) {
                this.buffer.column.edit(callback);
            } else {
                this.buffer.column.edit();
            }
            // Added By Aber Lu at 2017/08/22 for callback function end
        }
    },
    // Added By Aber Lu at 2017/08/22 for column update start
    'update': function(td, callback = null) {
        if (callback !== null) {
            var oTargetColumn = {};

            if (td.id != this.buffer.column.id) {
                oTargetColumn = new Column($(td));
            } else {
                oTargetColumn = this.buffer.column;
            }
            oTargetColumn.update($(td).attr("origin"), callback);
        } else {
            var oTargetColumn = {};

            if (td.id != this.buffer.column.id) {
                oTargetColumn = new Column($(td));
            } else {
                oTargetColumn = this.buffer.column;
            }
            oTargetColumn.update($(td).attr("origin"));
        }
    },
    // Added and Modified By Aber Lu at 2017/08/22 for column update end
    'search': function () {
        // 如果dialog不存在, 則init
        if ($('.dailogBg').length == 0) {
            $table = $('<table>');
            $table.css({'width': '330px'});

            // 將 searchBar 的內容抓出來 塞到 table 裡面
            var relatedControl = false;

            async.waterfall([
                function initTable(next) {
                    $("div#zdn_search_form>div").each(function(idx) {
                        $div = $(this);
                        // 如果此項目有兩個label
                        if ($(this).find("label").length > 1) {
                            $(this).find("label").each(function() {
                                $td1 = $('<td>').append($(this).html()).css({'text-align': 'right'});
                                // Modified By Aber Lu at 201807/24 這邊改為clone, 避免原始的被拿掉 start
                                $td2 = $('<td>').append($(this).next());
                                // Modified By Aber Lu at 201807/24 這邊改為clone, 避免原始的被拿掉 end
                                if (!$div.is(":visible")) {
                                    if (typeof $div.attr("id") !== typeof undefined) {
                                        $tr = $('<tr name="' + $div.attr("id") + '" style="display:none;">').append($td1).append($td2);
                                    } else {
                                        $tr = $('<tr style="display:none;">').append($td1).append($td2);
                                    }
                                } else {
                                    if (typeof $div.attr("id") !== typeof undefined) {
                                        $tr = $('<tr name="' + $div.attr("id") + '">').append($td1).append($td2);
                                    } else {
                                        $tr = $('<tr>').append($td1).append($td2);
                                    }
                                }
                                // 2022/05/16 Added By Neil 加上欄位備註
                                $($tr).find('td').eq(1).append($(this).parent().find("span.search-column-remark").get(0));
                                $table.append($tr);
                            });
                        // 假如只有一個label
                        } else if ($(this).find("label").length === 1 ) {
                            $td1 = $('<td>').append($(this).find("label").html()).css({'text-align': 'right'});
                            // Modified By Aber Lu at 201807/24 這邊改為clone, 避免原始的被拿掉 start
                            $td2 = $('<td>').append($(this).children().not('label'));
                            // Modified By Aber Lu at 201807/24 這邊改為clone, 避免原始的被拿掉 end
                            // Added By Aber Lu at 2017/02/07 修改 start
                            if (!$div.is(":visible")) {
                                if (typeof $div.attr("id") !== typeof undefined) {
                                    $tr = $('<tr name="' + $div.attr("id") + '" style="display:none;">').append($td1).append($td2);
                                } else {
                                    $tr = $('<tr style="display:none;">').append($td1).append($td2);
                                }
                            } else {
                                if (typeof $div.attr("id") !== typeof undefined) {
                                    $tr = $('<tr name="' + $div.attr("id") + '">').append($td1).append($td2);
                                } else {
                                    $tr = $('<tr>').append($td1).append($td2);
                                }
                            }
                            // Added By Aber Lu at 2017/02/07 修改 end
                            $table.append($tr);
                        }
                    }).promise().done(function () {
                        return next(null);
                    });
                },
                function makeupTable(next) {
                    $('tr td:first-child label', $table).css({'float': 'right'});
                    $('tr td:first-child', $table).css({'padding-right': '0px'});
                    $('body').append($table);
                    var tConfig = {
                        'title': '',
                        'type': 'html',
                        'end': '<input type="reset" name="reset" value="清除"><input type="submit" name="search" value="查詢">',
                    };
                    $('body').dailog(tConfig);
                    // 2023/05/30 Added By Neil 調整搜尋視窗寬度
                    $table.css({'width': $table.width() - 330 + $table.width()});

                    $('.dailogContent').append($table);
                    $.fn.dailog_start_action($table.width(), $table.height() + 60);
                    zTable.buffer.seacher = {};
                    return next(null);
                },
                function makeEvent(next) {
                    $('.dailogBg').unbind('click');
                    $('.dailogTitle>div>a').unbind('click');
                    $('.dailogBg').click(function () {
                        $('.dailogBg').hide();//.css({'display': 'none'});
                        $('.mid').hide();//.css({'display': 'none'});
                    });
                    $('.dailogTitle>div>a').click(function () {
                        $('.dailogBg').hide();//.css({'display': 'none'});
                        $('.mid').hide();//.css({'display': 'none'});
                    });

                    $('.dailogEnd input[type="reset"]').click(function (event) {
                        var obj = $('.dailogContent').find('select');
                        obj.val("");
                        obj.trigger('change');
                    });

                    $('.dailogEnd input[type="submit"]').click(function (event) {
                        event.preventDefault();
                        var obj = $('.dailogContent').find('input,select');
                        obj.each(function (index, element) {
                            var name = $(this).attr('name');
                            var value = $(this).val();
                            var aClasses = (typeof $(this).attr('class') !== typeof undefined) ? $(this).attr('class').split(" ") : [];
                            $.each(["s2", "datepick", "varchar", "datepick2", "hasDatepicker"], function(idx, classname) {
                                aClasses = jQuery.grep(aClasses, function(val) {
                                    return val != classname;
                                });
                            });

                            if (aClasses.length > 0) {

                            }
                            if (typeof(name) != "undefined") {
                                if ($(this).get(0).tagName === 'SELECT') {
                                    if (value == '' || value == '0') {
                                        if (typeof $(this).attr("allow_zero") !== typeof undefined && $(this).attr("allow_zero") == "1") {
                                            zTable.buffer.seacher[name] = value;
                                        } else {
                                            delete zTable.buffer.seacher[name];
                                        }
                                    } else if (value !== '' && value !== '0') {
                                        value = value === '00' ? '0' : value;
                                        zTable.buffer.seacher[name] = value;//output search
                                    }
                                } else if ($(this).get(0).tagName === 'INPUT') {
                                    if ($(this).hasClass('hasDatepicker')) {
                                        if ($(this).attr('id') == 'start_' + name) {
                                            zTable.buffer.seacher[name + '_start'] = value;
                                        } else if ($(this).attr('id') === 'end_' + name) {
                                            zTable.buffer.seacher[name + '_end'] = value;
                                        }
                                        // Added By Aber Lu at 2019/09/26 修正datepick2 月份搜尋錯誤 start
                                        else {
                                            zTable.buffer.seacher[name] = value;
                                        }
                                        // Added By Aber Lu at 2019/09/26 修正datepick2 月份搜尋錯誤 end
                                        // 2022/05/16 Added By Neil 新增 range 範圍 type
                                    } else if (this.getAttribute('data-type') == 'range') {
                                        if ($(this).attr('id') == 'start_' + name) {
                                            if (name in zTable.buffer.seacher) {
                                                zTable.buffer.seacher[name].start = value;
                                            } else {
                                                zTable.buffer.seacher[name] = {start: value}
                                            }
                                        } else if ($(this).attr('id') === 'end_' + name) {
                                            if (name in zTable.buffer.seacher) {
                                                zTable.buffer.seacher[name].end = value;
                                            } else {
                                                zTable.buffer.seacher[name] = {end: value}
                                            }
                                        } else {
                                            zTable.buffer.seacher[name] = value;
                                        }
                                    } else {
                                        zTable.buffer.seacher[name] = value;
                                    }
                                }
                            }
                        });
                        $('.dailogBg').hide();//.css({'display': 'none'});
                        $('.mid').hide();//.css({'display': 'none'});
                        zTable.goPage(0);
                    });

                    // Added By Aber Lu at 2018/02/08 增加事件related 聯動事件 start
                    $('div#zdn_search_form>div').each(function(index) {
                        if (typeof $(this).attr("related") !== typeof undefined) {
                            var aRelated = jQuery.parseJSON(decodeURIComponent($(this).attr("related")));
                            var id = $(this).attr("id");
                            // 添加click事件
                            $("tr[name=" + id + "]").find("select").on("change", function() {
                                if (($(this).val()).trim().toLowerCase() === "1") {
                                    $.each(aRelated, function(idx, value) {
                                        $("tr[name=" + value + "]").show();
                                    });
                                    $('.dailogContent').find($('.' + id)).each(function() {
                                        $(this).val("");
                                    });
                                } else {
                                    $.each(aRelated, function(idx, value) {
                                        $("tr[name=" + value + "]").hide();
                                    });
                                    $('.dailogContent').find($('.' + id)).each(function() {
                                        $(this).val("");
                                    });
                                }
                            });
                        }
                    });
                    // Added By Aber Lu at 2018/02/08 增加事件related 聯動事件 start

                    $('.dailogBg').on('show', function() {
                        removeMouseWheelEvent();
                    });
                    $('.dailogBg').on('hide', function() {
                        addMouseWheelEvent();
                    });

                    // 2023/01/17 Added By Neil 調整背景遮照長寬
                    $('.dailogBg').css('width', '100vw').css('height', '100vh');
                    return next(null);
                },
            ], function(err, result) {
                if (err) {
                    console.log(err);
                    return;
                } else {
                    $('.dailogBg').show();//.css({'display': 'block'});
                }
                return;
            });
        } else {
            $('.dailogBg').show();//.css({'display': 'block'});
            $('.mid').show();//.css({'display': 'block'});
        }
    },

    'delete': function (fn) {
        // 2025/12/12 [後台資料表格對齊] Neil 修正 selector
        if (this.hasNewRows()) {
            this.newRows().remove();
        } else {
            var row = this.selectedRows();
            if (row.length === 1) {
                var id = row.attr('id');
                var index = row.children('td').eq(0).text();

                z_confirm("資料刪除後即無法復原，您確定要刪除第" + index + "項資料嗎？",
                    function () {
                        var delete_data = {'delete': id};
                        $.post(get_url(), delete_data, function (data) {
                            if (data == 'success') {
                                if (zTable.afterDelete) zTable.afterDelete.call(this, id);
                                zTable.goPage();
                            } else {
                                z_alert(data);
                            }
                        }).fail(function(a, b, c) {
                            console.log(a, b, c);
                        });
                    },
                    function () {
                    }, "確認刪除資料");
            } else if (row.length > 1) {
                z_confirm("資料刪除後即無法復原，您確定要刪除此" + row.length + "項資料嗎？",
                    function () {
                        row.each(function (index) {
                            var id = $(this).attr('id');
                            var index = $(this).children('td').eq(0).text();
                            var delete_data = {'delete': id};
                            $.post(get_url(), delete_data, function (data) {
                                if (data == 'success') {
                                    if (zTable.afterDelete) zTable.afterDelete.call(this, id);
                                    zTable.goPage();
                                } else {
                                    z_alert(data);
                                }
                                
                            }).fail(function(a, b, c) {
                                console.log(a, b, c);
                            });
                        });
                    },
                    function () {
                    }, "確認刪除資料");
            } else {
                z_alert("您尚未選取任何一行資料！");
            }
        }
    },
    // Added Callback function By Aber Lu at 2017/08/22
    'addNewRow': function (callback = null) {
        var page_name = getPageName();//2019-09-09 shang 修正 帶入顧客後未設價別之後續顯示 start 【06-04】 end
        ret = '';
        // 2025/12/12 [後台資料表格對齊] Neil 修正 selector
        if (this.hasNewRows()) {
            ret = zTable.save();
            if (ret != 'success') {
                return;
            }
        }

        var row = $('<tr>').addClass('new_row').addClass('zdn_thbody_td').append($('<td>').text('＋').css({
            'text-align': 'center',
            'width': '32px'
        }));
        for (var i = 0; i < this.option.length; i++) {
            var opt = this.option[i];
            // 2024/01/23 Added By Neil [歐客佬]notShow 判斷
            if (opt.notShow) {
                continue;
            }
            var td = $("<td>").attr("type", opt.type).attr('name', 'td_' + opt.id).addClass('zdn_thbody_td').css({"text-align": "center"});
            if (opt.width != "") {
                td.css('width', opt.width);
            }


            if ($.inArray((i + 1), this.buffer.hidden) !== -1) {
                td.addClass('td_hidden');
            }

            if (opt.insert) {
                //log(opt);
                var w = opt.width.match(/\d+/);
                switch (opt.type) {
                    case 'boolean':
                        td.html($('<input>').attr('type', 'checkbox'));
                        break;
                    case 'option':
                        //2019-09-09 shang 修正 帶入顧客後未設價別之後續顯示 start 【06-05】
                        if (opt.defaultValue == "") {
                            td.html(opt.getHtmlObj(""));
                        }else{
                            if( (page_name == "maintain/customer" && getTheadName(opt.id) == "價別") || (page_name == "maintain/items" && getTheadName(opt.id) == "計稅")){//用頁面與欄位名來區分
                                td.html(opt.getOption3(opt.defaultValue));//沒有預設0的選項
                            }else{
                                td.html(opt.getHtmlObj(opt.defaultValue));
                            }
                        }
                        //2019-09-09 shang 修正 帶入顧客後未設價別之後續顯示 end 【06-05】
                            break;
                    case 'option2':
                        td.html(opt.getHtmlObj(''));
                        if (opt.width !== "") {
                            td.find('select').width(w - 20).select2();
                        } else {
                            td.find('select').addClass("auto_width").select2();
                        }
                        td.find('select').change(function (e) {
                            if ($(this).val() != 0) {
                                $(this).parent('td').removeClass('for_insert');
                            } else if (opt.need === true && $(this).val() == 0) {
                                $(this).parent('td').addClass('for_insert');
                            }
                        });
                        break;
                    case 'check':


                        break;
                    /* 2016-05-03 圖片新增時，可以將圖片一併複製過去 */
                    case 'image':
                    case 'image3':
                        $input = $('<input>');
                        td.html($input.attr('type', 'hidden'));
                        break;
					// Added at 2018/11/23 By Aber Lu 增加 datatype = time
                    case 'time':
                        $input = $('<input>');
                        if (opt.width !== "" && !opt.width.match(/[\%]+/)) {
                            td.html($input.attr('type', 'time').css("width", w - 5));
                        } else {
                            td.html($input.attr('type', 'time').addClass("auto_width"));
                        }
                        break;
                    default:
                        $input = $('<input>');
                        if (opt.width !== "" && !opt.width.match(/[\%]+/)) {
                            td.html($input.attr('type', 'text').css("width", w - 5));//2018-03-27 shang
                        } else {
                            td.html($input.attr('type', 'text').addClass("auto_width"));
                        }
                        if (opt.defaultValue != "") {
                            td.html($input.attr('type', 'text').val(opt.defaultValue));
                        }
                        if (opt.type == 'unique') {
                            if ($("#ztable_autoInsert").is(':checked')) {
                                $input.attr("disabled", "true");
                            }
                            $input.blur(function (e) {
                                if (!($("#ztable_autoInsert").is(':checked'))) {
                                    var val = $(this).val();
                                    if (!(/[a-zA-Z0-9\-_]+/g.test(val))) {
                                        z_alert('編號只能輸入數字、英文、底線、減號!!');

                                    }
                                }
                            });
                        }
                }
            } else {
                td.html('-');
            }
            if (opt.need === true) {
                td.addClass('for_insert');
            }
            if ($.inArray((i + 1) + "", this.buffer.hidden) !== -1) {
                td.css("display", "none");
            }
            row.append(td);
        }
        //----填充 預設值
        $reference = '';
        // 2025/12/12 [後台資料表格對齊] Neil
        const selectedRows = this.selectedRows();
        if (selectedRows.length > 0) {
            $reference = selectedRows.eq(selectedRows.length - 1).clone();
        } else {
            // 2025/12/12 [後台資料表格對齊] Neil
            const rows = this.rows();
            $reference = rows.eq(rows.length - 1).clone();
        }
        for (var i = 0; i < $('td', row).length; i++) {
            if ($reference != '' && $reference.length > 0) {
                $td = $('td', row).eq(i);
                if ($td.has('input').length && $('td', $reference).eq(i).attr('type') != 'unique') {
                    switch ($('input', $td).attr('type')) {
                        case 'checkbox':
                            $rTd = $('td', $reference).eq(i);
                            if ($('input', $rTd).prop("checked")) {
                                $('input', $td).prop("checked", true);
                            }
                            break;
                        /* 2016-05-03 圖片預設值帶入*/
                        case 'hidden':
                            //不再將上一筆圖片路徑設定為新資料的圖片預設值
                            //修正因複製上一筆預設值, 導致刪除新資料時會刪除上一筆的圖片, 進而同步失敗->
                            //				$rTd = $('td',$reference).eq(i);
                            //				$('input',$td).val( $rTd.find("a").data("img") );
                            $('input', $td).val("");
                            //<-
                            break;
                        default:
                            $rTd = $('td', $reference).eq(i);
                            if ($('input', $rTd).length > 0) {
                                $('input', $td).val($('input', $rTd).val());
                            } else {
                                $('input', $td).val($rTd.html());
                            }
                            break;
                    }
                } else if ($td.has('select').length && $('td', $reference).eq(i).attr('type') != 'unique') {
                    $rTd = $('td', $reference).eq(i);
                    $select = $td.children();
                    for (var p = 0; p < $('option', $select).length; p++) {
                        if ($('select', $rTd).length > 0) {
                            if ($('option', $select).eq(p).html() == $('option:selected', $rTd).html()) {
                                $('option', $select).eq(p).attr('selected', 'selected')
                            }
                        } else {
                            if ($('option', $select).eq(p).html() == $rTd.html()) {
                                $('option', $select).eq(p).attr('selected', 'selected')
                            }
                        }
                    }
                }

                // Added By Neil at 2021/05/27 新增時掛載日期元件
                if ($td.attr('type') === 'date') {
                    mountDate($('input', $td));
                }
            }
        }


        // 2025/12/12 [後台資料表格對齊] Neil 修正 selector
        this.body().append(row);
        const newRowSelector= this.selector().newRow;
        $(`${newRowSelector} td.for_insert`).each(function (index, element) {
            var self = $(this);
            $(this).children().blur(function (e) {
                if ($(this).val() == "" || ($(this).val() == "0" && this.tagName === "SELECT") && !self.hasClass('for_insert')) {
                    // Added By Aber Lu at 2017/08/22 start
                    if (this.disabled) {
                        return;
                    }
                    // Added By Aber Lu at 2017/08/22 end
                    self.addClass('for_insert');
                } else if ($(this).val() != "") {
                    self.removeClass('for_insert');
                }
            });
        });
        $(".auto_width").each(function (index, element) {
            $(this).width($(this).parent("td").width() - 20);
        });
        $('input,select', row).eq(0).focus();
        //log("ztable")

        // Added By Aber Lu at 2017/08/22 for callback function start
        if (callback !== null) {
            return callback();
        }
        // Added By Aber Lu at 2017/08/22 for callback function end
    },
    // Add parameters
    'save': function (modiColumn = null) {
        // 2025/12/12 [後台資料表格對齊] Neil 修正 selector
        var self = this.newRows();
        if (self.length === 1) {
            self.find('input,select').blur();
            if ($("#ztable_autoInsert").is(':checked')) {
                self.children('td.for_insert').removeClass('for_insert');
            }
            if (self.children('td.for_insert').length > 0) {
                z_alert('您尚有必填欄位未輸入！');
            } else {
                var arr = [];
                self.children('td:not(:first)').each(function (index, element) {
                    var type = $(this).attr("type");
                    if (zTable.option[index].insert) {
                        if (type === 'boolean') {
                            var value = $(this).find('input').get(0).checked ? 1 : 0;
                        } else if (type === 'option' || type === 'option2') {
                            var value = $(this).find('select').val();
                        } else {
                            if ($("#ztable_autoInsert").is(':checked') && $(this).find('input').is(':disabled')) {
                                var value = "auto";
                                var digit = $('#ztable_autoInsert_digit').val();
                            }
                            else {
                                // Modified By Aber Lu at 2017/08/23 start
                                if (modiColumn !== null && modiColumn == $(this).attr('name')) {
                                    var value = $(this).attr("origin") ? $(this).attr("origin") : $(this).find('input').val();
                                } else {
                                    var value = $(this).find('input').val();
                                }
                                // Modified By Aber Lu at 2017/08/23 end
                            }

                        }
                        arr.push({'key': $(this).attr('name'), 'value': value, 'digit': digit});
                    }
                });
                ret = '';

                $.post(get_url(), {'insert': JSON.stringify(arr)}, function (data) {
                    // Added By Aber Lu at 2019/06/04 for input check
                    try
                    {
                        var json = $.parseJSON(data);
                        if (typeof json === "object" && json) {
                            if (isset(json["success"]) &&
                                !json["success"]) {
                                if (isset(json["message"])) {
                                    z_alert(json["message"]);
                                } else {
                                    z_alert("資料寫入失敗");
                                }
                                return;
                            }
                        }
                    }
                    catch(e)
                    {
                    }
                    ret = data;
                    if (data == 'success') {
                        zTable.goPage();
                    } else {
                        z_alert(data);
                    }

                }).fail(function(a,b,c) {
                    console.log(a, b, c);
                });
                return ret;
            }
        } else {
            z_alert('請先新增一行，並輸入資料！');
        }
    },
    goPage: function (offset) {
        if (!isset(offset)) {
            var offset = this.buffer.offset;
        } else if (offset === 'html') {
            // 2022/05/04 [後台資料表格對齊] Neil 列印功能重構，提取至 zTable.print
            this.print.exec();
            return;
        } else if (offset === 'excel5') {//output search
            // 2022/05/04 [後台資料表格對齊] Neil 驗證匯出 Excel 筆數
            if (!checkOutputExcel()) {
                return false;
            }

            // 2022/05/04 [後台資料表格對齊] Neil output 符號調整
            var url = get_url() + (/\?/.test(get_url()) ? '&': '?') + "output=" + offset;
            if (JSON.stringify(this.buffer.seacher) != "{}") {
                // 2022/05/04 [後台資料表格對齊] Neil encodeURIComponent 參數
                url += '&seacher=' + encodeURIComponent(JSON.stringify(this.buffer.seacher));
            }
            if (this.buffer.order != "") {
                url += '&order=' + this.buffer.order;
            }
            window.open(url);
            return true;
        } else {
            this.buffer.offset = offset;
        }
        this.loading();
        var arg = {'offset': offset, 'ajax': 1};
        arg.seacher = JSON.stringify(this.buffer.seacher);
        if (this.buffer.order !== '') {
            arg.order = this.buffer.order;
        }

        $.ajax(get_url(), {
            async: false,
            data: arg,
            type: 'POST',
            success: function (data) {
                data = $.parseJSON(data);
                // 2022/11/04 Added By Neil [zTable.goPage() Before 回調]
                zTable.goPageBefore(data);
                // 2022/05/04 Modified By Neil 後台資料表格對齊，已移除 #zdn_thead 內容
                if (!this.isTableAlignment) {
                    $("#zdn_thead").html(data.thead);
                }
                $("#zdn_tbody").html(data.tbody);
                $("#zdn_tfoot").html(data.tfoot);
                zTable.hidden();
                setTimeout('zTable.fix()', 200);
                multipleSelect();
                $('td[type="boolean"]').children('input').click(function (e) {
                    e.stopPropagation();
                    zTable.buffer.column = new Column($(this).parent());
                    zTable.buffer.column.edit();
                });
                // 2022/05/04 [後台資料表格對齊] Neil 移除庫存查詢邏輯
                // 2022/11/04 Added By Neil [zTable.goPage() After 回調]
                zTable.goPageAfter(data);
            },
        }).fail(function(a, b, c) {
            console.log(a);
            console.log(b);
            console.log(c);
        });
    },
    // 2022/11/04 Added By Neil [增加 Go Page 回調]
    goPageBefore: function (data) {
        // 2022/05/04 [後台資料表格對齊] Neil
        typeof this.hooks.page.before === 'function' && this.hooks.page.before(data);
    },
    goPageAfter: function (data) {
        typeof this.hooks.page.after === 'function' && this.hooks.page.after(data);
        // 2022/05/04 Neil 後台資料表格對齊
        this.calc.do && this.calc.exec();
        document.body.dispatchEvent(new Event('RefreshZdnfreezeColumn'));
    },
    // 2023/05/30 Added By Neil 已選列
    selectedRows: function () {
        // 2025/12/12 [後台資料表格對齊] Neil 修正 selector ：在表格對齊的版本中，使用 #zdn_tbody 會造成取得 dom 的 rowIndex 有誤
        return recordTable.selectedRows();
    },
    // 2022/05/04 [後台資料表格對齊] Neil 合計
    calc: {
        do: false,// 設為 true 在換頁後才會執行合計
        before: null,// 渲染前 hook
        after: null,// 渲染後 hook
        decorate: null,// 裝飾合列行，例： (dom) => dom.addClass('className')，dom 是合計 tr 元素
        align: 'center',// 合計列的欄位對齊
        excludes: [],// 排除欄位
        isFetchType: function (i, cols) {
            const colType = cols.eq(i).attr('type');
            return colType == 'price' || colType == 'float' || colType == 'range';
        },
        isExcludeColumn: function (i, cols) {
            const name = cols.eq(i).attr('name')
            return !!this.excludes.length ? this.excludes.includes(name) : false;

        },
        // 取得要計算的欄位
        fetchColumns: function (row) {
            let columns = new Array();
            delete columns.__proto__.insert;
            const cols = $('td', row);
            for (var i = 0; i < cols.length; i++) {
                if (this.isExcludeColumn(i, cols)) {
                    continue;
                }

                if (this.isFetchType(i, cols) && !cols.eq(i).hasClass('td_hidden')) {
                    columns.push(i)
                }
            }
            return columns;
        },
        exec: function () {
            typeof this.before === 'function' && this.before();
            if( $("tr.zdn_calculate").length > 0 ){
                $("tr.zdn_calculate").remove();
            }
            // 2022/05/04 [後台資料表格對齊] Neil
            $tr = recordTable.rows();
            let priceColumn = new Array();
            if($tr.length>0){
                // 2022/05/04 [後台資料表格對齊] Neil 修正變數
                const row = $tr.eq(0);
                priceColumn = this.fetchColumns(row);
            }
            if(priceColumn.length>0){
                var total = new Array();
                delete total.__proto__.insert;
                for(var i=0 ; i<priceColumn.length ; i++){
                    total.push(0)
                }
                // 2022/05/04 [後台資料表格對齊] Neil
                for(var i=0 ; i < $tr.length ; i++){
                    var tr = $tr.eq(i);
                    for(var p=0 ; p<priceColumn.length ; p++){
                        var v = $('td',tr).eq( priceColumn[p] ).html();
                        if(/^\-{0,1}[0-9\,]+(\.\d+){0,1}$/.test(v)){
                            v = v.replace(/\,/g,'');
                            v = parseFloat(v);
                            total[p]+=v;
                            total[p] = total[p].toFixed(2);
                            total[p] = parseFloat(total[p]);
                        }
                    }
                }
                // 2022/05/04 [後台資料表格對齊] Neil
                var new_tr = $("<tr>").addClass("odd");
                if (_.isFunction(this.decorate)) {
                    new_tr = this.decorate(new_tr);
                }
                new_tr.appendTo(recordTable.body());
                delete new_tr.__proto__.insert;
                // 2022/05/04 [後台資料表格對齊] Neil
                for(var p=0 ; p<$tr.eq(0).find('td').length ; p++){
                    if(p==0){
                        $("<td>").append("合計").appendTo(new_tr);
                    }else{
                        var calNumber = false;
                        for(var i=0 ; i<priceColumn.length ; i++){
                            if(p==priceColumn[i]){
                                calNumber = true;
                                $("<td>").css('text-align',this.align).append(total[i]).appendTo(new_tr);
                                break;
                            }
                        }
                        if(!calNumber){
                            // 2022/05/04 [後台資料表格對齊] Neil
                            var classAttr =  $tr.eq(0).find('td').eq(p).attr('class')
                            $("<td>").append("").attr('class',classAttr).appendTo(new_tr);
                        }
                    }
                }
            }
            typeof this.after === 'function' && this.after();
        }
    },
}
ReferencePath = (ReferencePath == '') ? '..' : ReferencePath;

function addMouseWheelEvent() {
    window.addEventListener('mousewheel', mouseWheelCallback);
}
function removeMouseWheelEvent() {
    window.removeEventListener('mousewheel', mouseWheelCallback);
}
function mouseWheelCallback(e) {
    var scroll = $('#zdn_tbody').scrollTop();
    $('#zdn_tbody').scrollTop(scroll + (e.wheelDelta / 12 * -1));
}
//2019-09-09 shang 修正 帶入顧客後未設價別之後續顯示 start 【06-03】
  function getPageName(){
    var url = get_url().split("/");
    var count = url.length;
    var reData = "";
    if(count > 2){
        reData =url[count - 2]+"/"+url[count - 1];
    }
    return reData;
};

function getTheadName(id){
    var th = $('#ztb_'+id);
    return th.text();
}
//2019-09-09 shang 修正 帶入顧客後未設價別之後續顯示 end 【06-03】

// Added By Neil at 2022/01/21 驗證匯出 Excel 筆數
let outputExcelReg = new RegExp(/共(\d+)筆/)
let outputExcelMax = 16000;
/**
 * 驗證匯出 Excel 筆數
 * @returns {boolean}
 */
function checkOutputExcel() {
    let dataRange = document.querySelector('.ztable_data_range');
    if (dataRange && dataRange.innerText) {
        let match = dataRange.innerText.match(outputExcelReg);
        if (Array.isArray(match) && match[1] !== undefined) {
            let total = Number(match[1]);
            if (total === 0 || total > outputExcelMax) {
                z_alert(total === 0 ? '查詢結果為 0 筆，無法匯出。' : '查詢資料總筆數大於 ' + outputExcelMax + ' 筆，請分批匯出。');
                return false;
            }
        }
    }
    return true;
}

$(document).ready(function () {
    multipleSelect();
    $('#ztable_help').css('background-image', 'url(' + ReferencePath + '/images/system/Info.png)');
    $('#ztable_add_row').css('background-image', 'url(' + ReferencePath + '/images/system/Plus.png)');
    $('#ztable_del_row').css('background-image', 'url(' + ReferencePath + '/images/system/Delete.png)');
    $('#ztable_save').css('background-image', 'url(' + ReferencePath + '/images/system/Apply.png)');
    $('#ztable_sort_desc').css('background-image', 'url(' + ReferencePath + '/images/system/Down.png)');
    $('#ztable_sort_asc').css('background-image', 'url(' + ReferencePath + '/images/system/Up.png)');
    $('#ztable_hidden').css('background-image', 'url(' + ReferencePath + '/images/system/Switch.png)');
    $('#ztable_search').css('background-image', 'url(' + ReferencePath + '/images/system/View.png)');
    $('#ztable_output').css('background-image', 'url(' + ReferencePath + '/images/system/Next.png)');
    $('#ztable_print').css('background-image', 'url(' + ReferencePath + '/images/system/printer.png)');

    $("#ztable_autoInsert").click(function () {
        if ($(this).is(':checked'))
            $('td[type=unique]').find('input').attr('disabled', true);
        else
            $('td[type=unique]').find('input').attr('disabled', false);
    });

    /*觸控捲動*/
    $('#zdn_tbody').mousedown(function (event) {
        orig = event.clientY;
        $(document).mousemove(function (event) {
            var now = $('#zdn_tbody').scrollTop();
            var oy = event.clientY - orig;
            $('#zdn_tbody').scrollTop(now + oy);
        });
    });

    // Added By Aber Lu at 2018/02/08 start
    addMouseWheelEvent();
    // Added By Aber Lu at 2018/02/08 end

    $(document).mouseup(function () {
        $(this).unbind("mousemove");
    });
    $('td[type="boolean"]').children('input').click(function (e) {
        e.stopPropagation();
        zTable.buffer.column = new Column($(this).parent());
        zTable.buffer.column.edit();
    });
    /* search  修改 */
    $('#zdn_search_form').css({'visibility': 'hidden'});

    //F1
    window.key['112'] = function (e) {
        if ($("#dialogHelp").dialog('isOpen')) {
            $("#dialogHelp").dialog('close');
        } else if ($('#ztable_help').size() > 0) {
            $("#dialogHelp").dialog('open');
        }
    }

    //F2
    window.key['113'] = function (e) {
        if ($('#ztable_add_row').length > 0) {
            $('#ztable_add_row').click();
        } else {
            log('113 not exist');
        }
    }
    //F4
    window.key['115'] = function (e) {
        if ($('#ztable_del_row').length > 0) {
            $('#ztable_del_row').click();
        } else {
            log('115 not exist');
        }
    }
    //F8
    window.key['119'] = function (e) {
        if ($('#ztable_save').length > 0) {
            $('#ztable_save').click();
        } else {
            log('119 not exist');
        }
    }
    window.key['c70'] = function (e) {
        log($('.dailogContent input'))
        if ($('#ztable_search').length > 0) {
            $('#ztable_search').click();
            if ($('.dailogContent input').length > 0) {
                $('.dailogContent input').eq(0).focus();
            }
        } else {
            log('c70 not exist');
        }
    }
    //功能說明
    $('#ztable_help').parent().click(function () {
        $("#dialogHelp").dialog('open');
    });
    $("#dialogHelp").dialog({
        title: '功能說明',
        autoOpen: false,
        modal: true,
        height: 750,
        width: 800,
        buttons: [{
            text: "我瞭解了", click: function () {
                $(this).dialog("close");
            }
        }]
    });
});
