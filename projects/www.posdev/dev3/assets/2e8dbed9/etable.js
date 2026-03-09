// 2024/01/23 Added By Neil [歐客佬]加上 Loader
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

// JavaScript Document
function get_url() {
    var url = window.location.toString();
    return url;
}
function getPageName(){
    var url = get_url().split("/");
    var count = url.length;
    var reData = "";
    if(count > 2){
        reData =url[count - 2]+"/"+url[count - 1];
    }
    return reData;
};
var getHtmlSelect = function (obj, val) {
    var html = $('<select>');
    for (var key in obj) {
        if (typeof obj[key] === "string") {
            var opt = $('<option>').attr("value", key).text(obj[key]);
            html.append(opt);
            if (isset(val) && val === obj[key]) {
                opt.attr("selected", "selected");
            }
        }

    }
    return html;
}
var editOption = function (obj) {
    if (eTable.lock) {
        return false;
    }
    var self = $(obj);
    self.removeAttr("onclick");
    var id = self.data("id");
    var input = getHtmlSelect(eTable.columns[id].option, self.text());
    input.blur(function (e) {
        self.td.html(self.value);
        self.id = 0;
    }).change(function (e) {
        eTable.setValue(id, $(this).val());
    });
    self.html(input);
    input.focus();
}
var editOption2 = function (obj) {
    if (eTable.lock) {
        return false;
    }
    var self = $(obj);
    self.removeAttr("onclick");
    var id = self.data("id");
    var input = getHtmlSelect(eTable.columns[id].option);
    self.html(input);
    input.width(200).select2().on('close', function (e) {
        eTable.setValue(id, $(this).val());
    });
    input.select2('open');
}
var editText = function (obj) {
    if (eTable.lock) {
        return false;
    }
    var self = $(obj);
    var text = self.text();
    var input = $("<input>").val(text).attr("type", "text").width(parseInt(obj.style.width) - 10).blur(function (e) {
        self.html(text);
    }).keydown(function (e) {
        if (e.which === 13 || e.which === 9) {
            var val = this.value;
            if (self.hasClass("int")) {
                val = this.value.match(/\d+/) === null ? 0 : this.value.match(/\d+/)[0];
            } else if (self.hasClass("float") || self.hasClass("price") || self.hasClass("price2")) {
                if (this.value.match(/\d+[.]\d+/) === null) {
                    val = this.value.match(/\d+/) === null ? 0 : this.value.match(/\d+/)[0];
                } else {
                    val = Math.round(this.value.match(/\d+[.]\d+/)[0] * 100) / 100;
                }
            }
            eTable.setValue(self.data("id"), val);
        }
    });
    self.html(input);
    input.select();
    input.focus();
}
var editDate = function (obj) {
    var self = $(obj);
    var input = $('<input>').attr('type', 'text').val(self.value).css({"width": "95%"}).datepicker({
        dateFormat: "yy-mm-dd",
        dayNamesMin: ["日", "一", "二", "三", "四", "五", "六"],
        monthNames: ["一月", "二月", "三月", "四月", "五月", "六月", "七月", "八月", "九月", "十月", "十一月", "十二月"],
        monthNamesShort: ["一月", "二月", "三月", "四月", "五月", "六月", "七月", "八月", "九月", "十月", "十一月", "十二月"],
        changeYear: true,
        changeMonth: true,
        yearRange: 'c-100:c+5',
        onSelect: function (dateText, ui) {
            self.html(dateText);
            self.id = 0;
        },
        onClose: function (dateText, ui) {
            self.html(dateText);
            self.id = 0;
        }
    });
    self.html(input);
    input.focus();
}
var Column = function (obj, x, y) {
    var page_name = getPageName();//2019-10-24 shang float輸入預設值修改(盤點輸入) start【02】end
    var self = this;
    obj = obj || {};
    self.width = obj.width || "";
    self.type = obj.type || "";
    self.option = obj.option || [];
    self.id = obj.id || "0";
    self.align = obj.align || "center";
    self.forInsert = obj.forInsert || false;
    self.callback = obj.fn || null;
    self.x = x || 0;
    self.y = y || 0;
    //2019-08-09 shang 二次進貨修改 start 【4】
    //此參數 各別在"進貨輸入" 使用出現
    self.display = obj.display || null;
    //2019-08-09 shang 二次進貨修改 end 【4】
    var td = $("<td>").css({"text-align": self.align, "border": "#FFF 1px solid"}).addClass(self.type);
    if (self.forInsert) {
        td.addClass("need");
    }
    var value = "";
    switch (self.type) {
        case "int":
        case "float":
            value = 1;
            break;
        case "price":
            value = 0;
            break;
        case "price2":
            value = 0;
            break;
    }
    if (self.width === "") {
        td.addClass("auto_width");
    } else {
        td.width(self.width);
    }
    if (self.type === "index") {
        td.css("font-weight", "bold");
    }
    //2019-08-09 shang 二次進貨修改 start 【5】
    if(self.display == "none"){
        td.css("display", "none");
    }
    //2019-08-09 shang 二次進貨修改 end 【5】
    //2021-09-09 Beth add parameter 取出設定的原值  再get強迫轉換是什麼鬼= =
    self.getTd = function (flag = false) {
        return td.text(self.getValue(flag));
    }
    self.setValue = function (val) {
        var oldValue = value;
        if (val == "" && (self.type === "int" || self.type === "float")) {
            //2019-10-24 shang float輸入預設值修改(盤點輸入) start【03】
            if(page_name == "stock/collection"){
                value = 0;
            }else{
                value = 1;
            }
            //2019-10-24 shang float輸入預設值修改(盤點輸入) end【03】
        } else if (val == "" && self.type === "price") {
            value = 0;
        } else if (val == "" && self.type === "price2") {
            value = 0;
        } else {
            value = val;
        }
        if (self.callback && oldValue !== val) {
            self.callback(value, self.x, self.y);
        }
    }
    self.getValue = function (flag) {
        if (self.type === "boolean") {// 2024/01/23 Added By Neil [歐客佬]新增 type == boolean 取值
            return Number(!!td.find('input').get(0)?.checked)
        }

        if (flag) {
            return value;
        }
        if (self.type === "option" || self.type === "option2" || self.type === "data") {
            return self.option[value];
        } else if (self.type === "int" || self.type === "float" || self.type === "count+" || self.type === "count-" || self.type === "count*" || self.type === "price" || self.type === "price2") {
            return number_format(value);
        }

        return value;
    }
}
var eTable = {
    'columns': [{"id": "seq", "width": "30px", "type": "index", "align": "center"}],
    'rows': [],
    'lock': false,
    'canEdit': true,
    'rowCallback': false,
    'template': '',
    // 2022/11/04 Modified By Neil 增加顯式 Scroll Bar 參數
    'fix': function (explicit) {
        var content_h = $("#content").height();
        var tbody_h = $("#zdn_tbody table").height();
        var other_h = $("#zdn_controller").height() + $("#zdn_thead").height() + $("#zdn_tfoot").height();
        if ((tbody_h + other_h + 50) > content_h) {
            // 2022/11/04 Added By Neil POS 機觸控難以滾動，增加顯式 Scroll Bar 處理
            if (explicit) {
                $("#zdn_tbody").css("max-height", content_h - other_h - 50);
                $("#zdn_tbody").css({'overflow-y': 'auto'});
                return;
            }

            $("#zdn_tbody").height(content_h - other_h - 50);
            $("#zdn_tbody").niceScroll({"touchbehavior": 1, "emulatetouch": 1});
            $("#zdn_tbody").getNiceScroll(0).resize();
        } else {
            $("#zdn_tbody").css("height", "auto");
        }
    },
    'delete': function () {
        if (this.lock || !this.canEdit) {
            return false;
        }
        var id = $("tr.row_selected").data("id");
        if (isset(id)) {
            this.rows.splice(id, 1);
            this.draw();
        } else {
			// Modified By Aber Lu at 2019/11/26 修改為z_confirm 避免electron的 blur focus bug
            //if (window.confirm("您尚未選擇任何一筆資料，是否要全部刪除？")) {
			var oTemp = this;
			z_confirm("您尚未選擇任何一筆資料，是否要全部刪除？", function() {
                oTemp.rows = [];
                oTemp.draw();
            });
			//}
        }
    },
    'checkNeed': function () {
        var flag = true;
        $("td.need").each(function (index, element) {
            if ($(this).text() === "" || $(this).text() === "-" || $('input.cacheObj').size() > 0) {
                flag = false;
                return false;
            }
        });
        return flag;
    },
    'getObj': function () {
        var obj = [];
        for (var i = 0; i < this.rows.length; i++) {
            var nRow = this.rows[i];
            var tr = {};
            for (var j = 0; j < nRow.length; j++) {
                var nTd = nRow[j];
                tr[nTd.id] = nTd.getValue(true);
            }
            obj.push(tr);
        }
        return obj;
    },
    'loading': function (flag) {
        this.lock = flag;
        if (flag) {
            var cover = $("<div>").width($("#zdn_tbody").width()).height($("#zdn_tbody").height()).css({
                'position': 'absolute',
                'z-index': 'auto',
                'background-color': 'rgba(120,120,120,0.5)'
            }).append('<table style="height:100%;width:100%;"><tr><td align="center" valign="middle"><center><div class="loading">檔案傳輸中</div></center></td></tr></table>');
            $("#zdn_tbody").prepend(cover);
        }
    },
    'post': function (action, obj) {
        var self = this;
        // 2022/11/14 Added By Neil [儲存防連點]
        let notUnlock = false;
        $.ajax({
            type: "POST",
            url: window.location.toString(),
            data: {'ajax': action, 'data': JSON.stringify(obj)},
            cache: false,
            dataType: 'json',
            beforeSend: self.loading(true),
        }).done(function (data) {
            if (data.err) {
                z_alert(data.msg);
            } else {
                if (data.msg.length > 0) {
                    z_alert(data.msg);
                }
                // 2022/11/14 Added By Neil [儲存防連點]
                notUnlock = true;
                window.location = data.result;
            }
        }).fail(function (e) {
            z_alert(e.responseText);
        }).always(function () {
            // 2022/11/14 Added By Neil [儲存防連點]
            !notUnlock && self.loading(false);
        });
    },
    'save': function () {
        if (this.lock) {
            return false;
        }
        if ($("#zdn_tbody tbody tr").size() === 0) {
            z_alert("您尚未新增任何資料！");
        } else if (!this.checkNeed()) {
            z_alert("您尚有重要欄位未填！");
        } else {
            var data = {};
            $("#zdn_edit_form input,#zdn_edit_form select").each(function (index, element) {
                if (this.id !== "" && this.id.match(/s2id_autogen\d+/) === null) {
                    data[this.id] = this.value;
                }
            });
            data.list = this.getObj();
            this.post("save", data);
        }

    },
    'addNewRow': function () {
        if (this.lock || !this.canEdit) {
            return false;
        }
        var nRow = [];
        for (var i = 0; i < this.columns.length; i++) {
            nRow.push(new Column(this.columns[i], i, this.rows.length));
        }
        this.rows.push(nRow);
        this.draw();
    },
    'setRows': function (obj) {
        this.rows = [];
        for (var j = 0; j < obj.length; j++) {
            var nRow = [];
            var nObj = obj[j];
            for (var i = 0; i < this.columns.length; i++) {
                var column = new Column(this.columns[i], i, this.rows.length);
                column.setValue(nObj[this.columns[i].id]);
                nRow.push(column);
            }
            this.rows.push(nRow);
        }
        this.draw();
    },
    'setColumns': function (obj) {
        if (!this.lock) {
            var obj = JSON.parse(obj);
            for (var i = 0; i < obj.length; i++) {
                this.columns.push(obj[i]);
            }
        }
    },
    'getTdObj': function (id) {
        return this.rows[$("tr.row_selected").data("id")][id];
    },
    'setValue': function (id, val) {
        var td = this.getTdObj(id);
        td.setValue(val);
        this.draw();
    },
    'search': function () {
        if ($('.dailogBg').length == 0) {
            $table = $('<table>');
            $table.css({'width': '250px'});
            var obj = $('#zdn_search_form').find('input,select');
            var label = $('#zdn_search_form').find('label');
            for (i = 0; i < obj.length; i++) {
                $td = $('<td>').append(label.eq(i).clone()).attr({'width': '40%', 'align': 'right'});
                $inputClone = obj.eq(i);
                $td2 = $('<td>').append($inputClone);
                $tr = $('<tr>').append($td).append($td2);
                $table.append($tr);
            }
            $('tr td:first-child label', $table).css({'float': 'right'});
            $('tr td:first-child', $table).css({'padding-right': '0px'});

            $('body').append($table);
            var tConfig = {'title': '', 'type': 'html', 'end': '<input type="submit" name="search" value="查詢">'};
            $('body').dailog(tConfig);
            $('.dailogContent').append($table);
            $.fn.dailog_start_action($table.width(), $table.height() + 60);
            eTable.buffer.seacher = {};
            $('.dailogBg').unbind('click');
            $('.dailogTitle>div>a').unbind('click');

            $('.dailogBg').click(function () {
                $('.dailogBg').css({'display': 'none'});
                $('.mid').css({'display': 'none'});

            })
            $('.dailogTitle>div>a').click(function () {
                $('.dailogBg').css({'display': 'none'});
                $('.mid').css({'display': 'none'});
            })
            //$('.dailogEnd input[type="submit"]').click(function (event){});
        } else {
            $('.dailogBg').css({'display': 'block'});
            $('.mid').css({'display': 'block'});
        }
    },
    'goPage': function (offset) {
        if (offset === 'html') {
            var PrintObj = window.open('', 'printWindow', 'toolbar=yes,status=yes,menubar=yes,scrollbars=yes,copyhistory=no,resizable=yes');
            var docu = PrintObj.document;
            var $body = $('body', docu);
            var $tableHtml = $('<div>');
            $('table', $('#zdn_thead')).each(function () {
                $tableHtml.append($(this).clone());
            })
            $('table', $('#zdn_tbody')).each(function () {
                $tableHtml.append($(this).clone());
            })
            $('table', $('#zdn_tfoot')).each(function () {
                var clone = $(this).clone();
                clone.find('th').css('text-align', 'start');
                $tableHtml.append(clone);
            })
            if (eTable.template != '') {
                eTable.template = eTable.template.replace('{table}', $tableHtml.html());
                $body.append(eTable.template);
            } else {
                $body.append($tableHtml.html());
            }
            PrintObj.print();
            PrintObj.close();
            return;
        } else if (offset === 'excel5') {
            if (/\?/.test(get_url())) {
                var url = get_url() + "&output=" + offset;
            } else {
                var url = get_url() + "?output=" + offset;
            }
            if (typeof this.buffer.seacher != 'undefined' && this.buffer.seacher != '') {
                url += '&seacher=' + JSON.stringify(this.buffer.seacher);
            }
            window.open(url);
            return true;
        }
    },
    'draw': function () {
        $("#zdn_tbody tbody").html("");
        var buf = {};
        if (this.rows.length === 0) {
            $("#zdn_tfoot th").not(":first").text("");
        }

        // Modified By Aber Lu at 2018/08/21 修改為同步方式較為妥當 start
        var eTableObj = this;
        async.waterfall([
            function (next) {
                async.eachOfSeries(eTableObj.rows, function (row_obj, key, doneOfRow) {
                    var nRow = $("<tr>").data("id", key).addClass(key % 2 == 1 ? 'even' : 'odd');

                    if ((typeof eTableObj.rowCallback) === "function") {
                        eTableObj.rowCallback(row_obj);
                    }

                    async.waterfall([
                        function initCol(nextStep) {
                            async.eachOfSeries(row_obj, function (column, col_key, doneOfCol) {
                                if (column.type === "index") {
                                    column.setValue(key + 1);
                                }
                                if (column.type === "int" || column.type === "float" || column.type === "price" || column.type === "count") {
                                    if (key === 0) {
                                        buf[column.id] = 0;
                                        buf[column.id] += column.getValue(true) * 1;
                                    } else {
                                        buf[column.id] += column.getValue(true) * 1;
                                    }
                                }
                                var nTd = column.getTd();
                                //2021-09-09 Beth add price2 取出原值不做轉換
                                if (column.type === "price2"){
                                    nTd = column.getTd(true);
                                }
                                if (column.type === "link") {
                                    nTd.html('');
                                    $("<a>").append(column.getValue()).attr('href', column.option.link + column.getValue()).attr('style', "font-weight:bold").appendTo(nTd);
                                }
                                if (column.type === "link2") {
                                    nTd.html('');
                                    $("<a onclick='list_dialog("+key+")'>").append(column.getValue()).appendTo(nTd);
                                }
                                // 2024/01/23 Added By Neil [歐客佬]新增「領用」勾選欄位(type == boolean)
                                if (column.type === "boolean"){
                                    nTd.html($('<input>').attr('type', 'checkbox'));
                                }
                                nRow.append(nTd.data("id", col_key));
								/*async.setImmediate(function() {
									doneOfCol(null);
								});*/
                                return doneOfCol(null);
                            }, function (err) {
                                return nextStep(null);
                            });
                        },
                        function finalizeRow(nextStep) {
                            nRow.click(function () {
                                $("#zdn_tbody tr.row_selected").removeClass("row_selected");
                                $(this).addClass("row_selected");
                            });
                            $("#zdn_tbody tbody").append(nRow);
                            return nextStep(null);
                        }
                    ], function (err) {
						/*async.setImmediate(function() {
							doneOfRow(null);
						});*/
                        return doneOfRow(null);
                    });
                }, function (err) {
                    return next(null);
                });
            },
            function (next) {
                async.eachOfSeries(buf, function (val, key, doneOfBuf) {
                    $("th." + key + "_sum").text(number_format(val));
                    return doneOfBuf(null);
                }, function (err) {
                    return next(null);
                });
            },
            function (next) {
                if (eTableObj.canEdit) {
                    $("#zdn_tbody tbody td.text,#zdn_tbody tbody td.varchar,#zdn_tbody tbody td.int,#zdn_tbody tbody td.float,#zdn_tbody tbody td.price,#zdn_tbody tbody td.price2").attr("onclick", "editText(this)");
                    $("#zdn_tbody tbody td.option").attr("onclick", "editOption(this)");
                    $("#zdn_tbody tbody td.option2").attr("onclick", "editOption2(this)");
                    $("#zdn_tbody tbody td.date").attr("onclick", "editDate(this)");
                }
                eTableObj.fix();
				// Modified By Aber Lu at 2019/06/20 修正bug
				return next(null);
            }
        ], function (err) {
            if (err) {
                console.log(err);
				return;
            }
			return;
        });
        /*for(var i=0;i<this.rows.length;i++) {
         var row_obj = this.rows[i];
         var nRow = $("<tr>").data("id",i).addClass(i%2==1?'even':'odd');

         if((typeof this.rowCallback) === "function"){
         this.rowCallback(row_obj);
         }

         for(var j=0;j<row_obj.length;j++) {
         var obj = row_obj[j];
         if(obj.type === "index"){
         obj.setValue(i+1);
         }
         if(obj.type==="int" || obj.type==="float" || obj.type==="price"  || obj.type==="count"){
         if(i===0){
         buf[obj.id] = 0;
         buf[obj.id] += obj.getValue(true)*1;
         }else{
         buf[obj.id] += obj.getValue(true)*1;
         }
         }
         var nTd = obj.getTd();
         if(obj.type === "link"){
         nTd.html('');
         $("<a>").append(obj.getValue).attr('href',obj.option.link+obj.getValue()).attr('style',"font-weight:bold").appendTo(nTd);
         }
         nRow.append(nTd.data("id",j));
         }
         nRow.click(function(){
         $("#zdn_tbody tr.row_selected").removeClass("row_selected");
         $(this).addClass("row_selected");
         });
         $("#zdn_tbody tbody").append(nRow);
         }
         for(var key in buf){
         $("th."+key+"_sum").text(number_format(buf[key]));
         }
         if(this.canEdit){
         $("#zdn_tbody tbody td.text,#zdn_tbody tbody td.varchar,#zdn_tbody tbody td.int,#zdn_tbody tbody td.float,#zdn_tbody tbody td.price,#zdn_tbody tbody td.price2").attr("onclick","editText(this)");
         $("#zdn_tbody tbody td.option").attr("onclick","editOption(this)");
         $("#zdn_tbody tbody td.option2").attr("onclick","editOption2(this)");
         }

         this.fix();*/
        // Modified By Aber Lu at 2018/08/21 修改為同步方式較為妥當 end
    }
}
ReferencePath = (ReferencePath == '') ? '..' : ReferencePath;
$(function () {
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
