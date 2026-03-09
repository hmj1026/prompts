/**
 * Report Table
 */
class ReportTable {
    /**
     * 調整 Report Table 高度
     */
    static adjustHeight() {
        let excludHeight = $('body').width() >= 1080 ? 0 : $('footer').height();
        ['#header', '#mainmenu', '#status_line', '#zdn_controller', '#zdn_tfoot'].forEach((selector) => {
            excludHeight += $(selector).outerHeight(true);
        });

        $(".reportContainer.zdn_tbody").css("max-height", $(window).height() - excludHeight);
        $(".reportContainer.zdn_tbody").css({'overflow-y': 'auto'});
    }
}

$(document).ready(function () {
    setTimeout(function () {
        if ($('.reportContainer.zdn_tbody').length) {
            ReportTable.adjustHeight();
        }
    }, 50);
})
