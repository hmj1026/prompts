/**
 * 商品面版品項 // 2024/10/20 [金吉利] Added By Neil
 * @param i
 * @param obj
 * @param originPriceIndex 原價索引
 * @return {{sn:number,no:string,name:string,color:string,amount,number,originPrice:number,salesPrice:number,total:number,discount:string,remarkText:string,shortRemark:string,taxType:number,taxColor:string}}
 */
function OrderPanelItem(i, obj, originPriceIndex) {
    /** @var 序號 */
    this.sn = i + 1;

    /** @var 編號 //2023-12-28 Leo add [歐客佬] 零售產業加商品編號 */
    this.no = obj.getId();

    /** @var 名稱 // 2023/06/29 Added By Neil [寄杯(預訂)]裝飾品名 */
    this.name = !obj.isBooking ? obj.getName() : POS.list.booking.decorate(obj.getName());

    /** @var 顏色 */
    this.color = DataProvider.colors?.[obj.getColorNo()]?.remark ?? '';

    /** @var 數量 */
    this.amount = Math.round(obj.getAmount() * 100) / 100;

    /** @var 原價 */
    this.originPrice = obj.getPricelist()?.[originPriceIndex] ?? 0;

    /** @var 售價(單價) */
    this.salesPrice = Math.round(obj.getPrice()*100)/100;

    /** @var 小計 // 2024/01/23 Added By Neil [歐客佬(一)]前台顯示小數位數處理 */
    this.total = obj.getTotal().toDisplay();

    /** @var 折扣 */
    this.discount = obj.getDiscountVal();

    /** @var 備註 //2023/03/15 Dorado 是否顯示重量 - 電子秤重量 */
    this.remarkText = obj.getRemark(true);

    /** @var 短備註 */
    this.shortRemark = obj.getShortRemark();

    const taxType = obj.type === "book" ? 0 : obj.getTaxType();

    /** @var 稅別 */
    this.taxType = taxType;

    /** @var 稅別顏色 */
    this.taxColor = taxType >= 2 ? "red" : "";
}

/**
 * 商品面版已結品項(作廢、折讓單) // 2024/10/20 [金吉利] Added By Neil
 * @param i
 * @param obj
 * @param originPriceIndex 原價索引
 * @return {{sn:number,no:string,name:string,color:string,amount,number,originPrice:number,salesPrice:number,total:number,discount:string,remarkText:string,shortRemark:string,taxType:number,taxColor:string}}
 */
function OrderPanelSalesItem(i, obj, originPriceIndex) {
    /** @var 序號 */
    this.sn = i + 1;

    /** @var 編號 //2023-12-28 Leo add [歐客佬] 零售產業加商品編號 */
    this.no = obj.item_no;

    /** @var 名稱 // 2023/06/29 Added By Neil [寄杯(預訂)]裝飾品名 */
    this.name = obj.item_name;

    /** @var 顏色 */
    this.color = DataProvider.colors?.[obj.item_color]?.remark ?? '';

    /** @var 數量 */
    this.amount = Math.round(obj.saleslist_amount * 100) / 100;

    /** @var 原價 */
    this.originPrice = obj.price.split(',')?.[originPriceIndex] ?? 0;

    /** @var 售價(單價) */
    this.salesPrice = obj.item_saleprice;

    /** @var 小計 // 2024/01/23 Added By Neil [歐客佬(一)]前台顯示小數位數處理 */
    this.total = obj.saleslist_sum.toDisplay();

    const total = obj.saleslist_amount * obj.item_saleprice;
    /** @var 折扣 */
    this.discount = obj.saleslist_discount * 100 / (total == 0 ? 1 : total) + '%';

    /** @var 備註 //2023/03/15 Dorado 是否顯示重量 - 電子秤重量 */
    this.remarkText = obj.remark;

    /** @var 短備註 */
    this.shortRemark = obj.item_remark;

    /** @var 稅別 */
    this.taxType = null;

    /** @var 稅別顏色 */
    this.taxColor = "";
}

/**
 * 商品面版 // 2024/10/20 [金吉利] Added By Neil
 * @constructor
 */
function OrderPanel() {
    const originPriceIndexSelector = () => {
        return $('#order_panel_origin_price_index');
    };

    // 原價索引(在金吉利中使用價別1作為原價，提供其他價別填入參照，非計算前的原價)
    let originPriceIndex = Number(originPriceIndexSelector().val() ?? 0);
    const orderPanelColumns = $('#order_panel_columns').val();
    this.columns = isEmpty(orderPanelColumns) ?
        ['sn', 'name', 'amount', 'salesPrice', 'discount', 'total', 'remarkText'] : orderPanelColumns.split(',');

    this.append = function (i, obj, row) {
        const orderPanelItem = obj instanceof Item ? new OrderPanelItem(i, obj, originPriceIndex) : new OrderPanelSalesItem(i, obj, originPriceIndex);
        for (const column of this.columns) {
            if (column in orderPanelItem) {
                row.append($("<td>").html(orderPanelItem[column]).css("color", orderPanelItem.taxColor));
                continue;
            }
            row.append($("<td>").text('').css("color", orderPanelItem.taxColor));
        }
    }

    /**
     * 取得欄位索引
     * @return {number|null}
     */
    this.getColumnIndex = function (column) {
        const index = this.columns.indexOf(column);
        return index != -1 ? index : null;
    }

    /**
     * 有原價價別設定
     * @return {boolean}
     */
    this.hasOriginPrice = function () {
        return !! originPriceIndexSelector().length;
    }

    /**
     * 取得原價別索引
     * @return {number}
     */
    this.getOriginPriceIndex = function () {
        return originPriceIndex;
    }
}

$(function () {
    if (isObject(POS?.list)) {
        // 初始化商品面版列表
        POS.list.orderPanel = new OrderPanel();
    }
});