//顯示時間
(function($) {
	//初始配置
    var config = {
    				'ulclass':'ulset',
    				'liclass':'select',
    				'statement':{'select':'-','selected':'已選擇'},
    				//一次顯示幾個
    				//2021-05-24 Beth modify 6 to 10
    				'shownum':10,
                    'clear' : false //2021-09-10 shang 查詢條件保留 start【9】end

    			 };
	var ver	   = 'multselect';
	var removeObj = new Array();
	//擴充 FUNC
	$.fn.extend({
		//2021-03-25 Beth add 新增combo決定是否要 合併defaults 和 options 
		multselect:function(options, combo = true ,selected = []){//2021-09-10 shang 查詢條件保留 start【10】end
			//合併defaults 和 options 後面變數合併到前面變數
            $.extend( config , options );
			$(this).multselect_start(combo,selected);//2021-09-10 shang 查詢條件保留 start【11】end
			//回傳本身JQ物件
			return $(this);
		},
		//2021-03-25 Beth add 新增combo決定是否要 合併defaults 和 options 
		multselect_start:function(combo = true ,selected = []){//2021-09-10 shang 查詢條件保留 start【12】end
			if( $(this).is('select') && $('option',this).length>0 ){
				$(this).each(function (){
					var that = this;
                    var this_name = $(this).attr('name');//2021-09-10 shang 查詢條件保留 start【13】end
					var data = new Array();
					$('option',that).each(function (){
						var obj = new Object();
						obj.title = $(this).html();
						obj.value = $(this).attr('value');
						data.push( obj );
					})
					if( data.length>0 &&  typeof data[0]=='object'){
						var inputName = $(that).attr('name');
						var inputClass = $(that).attr('class');
						var $parent = $(that).parent();
						var x = $(that).position().left;
						var y = $(that).position().top;
						$(that).remove();
						//var $button = $('<input>').css({'left':x,'top':y}).attr({'type':'button','value':data[0].title,'class':inputClass});
						var $div = $('<div name="'+inputName+'">').css({'left':x,'top':y,'cursor':'pointer'}).attr({'class':inputClass});
						var $title = $('<div>').attr({'class':'multTitle'}).css({'width':'80%','height':'100%','float':'left'}).html(config.statement.select);
						var $pic = $('<div>').attr({'class':'multPic'}).css({'width':'12%','float':'left'}).html('&nabla;');
						$div.append($title).append($pic);
						$parent.append($div);
						function show(){
							var that = this;
							if(!inputName){
								log('錯誤');
								return ;
							}
							if($('.'+config.ulclass).length>0){
								$('.'+config.ulclass).multselect_remove(inputName , $div , data , $('.'+config.ulclass) );
								return ;
							}
							var isSelect = new Array();
							if( $('input[name="'+inputName+'[]"]').length>0 ){
								$('input[name="'+inputName+'[]"]').each(function(){
									isSelect.push($(this).val());
								});
								$('input[name="'+inputName+'[]"]').remove();
							}
							//2021-09-10 shang 查詢條件保留 start【14】
                            if(isSelect.length == 0 && selected[this_name] != undefined && config['clear'] == false){
                                isSelect = selected[this_name];
                            }
			    //2021-09-10 shang 查詢條件保留 end【14】
							var $ul = $('<ul>');
							var padding = pxToInt($div.css('margin-bottom'))+pxToInt($div.css('padding-bottom'));
							var ulX = x+pxToInt($div.css('margin-left'))+pxToInt($div.css('padding-left'));
							var ulY = y+$div.height()+(padding*2);
							$ul.css({'position':'absolute','z-index':9999,'left':ulX,'top':ulY})
							$ul.addClass(config['ulclass']);
							for(member in data){
								if(typeof data[member]=='object'){
									var $li = $('<li>');
									$li.css({'cursor':'pointer'});
									//2021-03-25 Beth add 可選擇是否要串在一起
									if (combo)
										$li.html(data[member].value+'&nbsp;'+data[member].title);
									else 
										$li.html(data[member].title);
									$ul.append($li);
									if(isSelect.length>0){
										for(mem in isSelect){
											if( typeof isSelect[mem] == 'string'){
												if(isSelect[mem]==data[member].value){
													$li.attr({'class':config['liclass']});
                                                    $('.multTitle',$parent).html(config.statement.selected);//2021-09-10 shang 查詢條件保留 start【15】end
												}
											}
										}
									}
									$li.click(function (){
										if( $(this).attr('class') == config['liclass'] ){
											$(this).attr({'class':''});
										}else{
											$(this).attr({'class':config['liclass']});
										}
										$parent = $(that).parent();
										if($('.'+config.liclass,$ul).length==0){
											$('.multTitle',$parent).html(config.statement.select);
										}else{
											$('.multTitle',$parent).html(config.statement.selected);
										}
									})
								}
							}
							$div.unbind('mouseleave');
							$div.mouseleave(function() {
								$ul.multselect_remove(inputName,$div,data,$ul);
							});
							$div.append($ul);

							$cacheli = $('li',$ul);
							if($cacheli.length>config.shownum){
								// 2024/08/07 [CPOS] By Neil Modified 調整依原程式直接取，eq(0) 若是空字串，則 H 會為零，高度會為零的問題
								let H = 21;
								for (let i = 0, max = $cacheli.length; i < max; i++) {
									if ($cacheli.eq(i).html()) {
										H = $cacheli.eq(i).height();
										break;
									}
								}
								// var H = $cacheli.eq(0).height();
								var totalH = H*config.shownum;
								//$cacheli.css({'width':'10%'});
								$ul.css({'height':totalH,'overflow-y':'scroll'});
							}
						}
						$('.multTitle',$div).click(show);
						$('.multPic',$div).click(show);
					}
				});
					

			}
		},
		multselect_remove:function(name,parent,data,ul){
			if(!!name && !!parent.append){
				var $li = ul.children();
				$li.each(function (){
					if($(this).attr('class')==config['liclass']){
						var $input = $('<input>');
						var v = null;
						for(obj in data){
							if(!!data[obj].title && data[obj].value){
								if( (data[obj].value+'&nbsp;'+data[obj].title) == $(this).html() ){
									v = data[obj].value;
								}
								//2021-04-06 Beth modify combo false 時加入，shang找到的OXO 
								else if(data[obj].title == $(this).html() ){
									v = data[obj].value
								}	
							}
						}
						if(!!v){
							var exist = false;
							$('input[name="'+name+'[]"]').each(function (){
								if(v==$(this).val()){
									exist = true;
								}
							})
							if(!exist){
								$input.attr({'type':'hidden','value':v,'name':name+'[]'});
								parent.append($input);
							}
						}
					}
				})
			}
			$('ul.'+config['ulclass']).remove();
		},
	});
}(jQuery));