var realtimeHub, rtOrdersRevenueChart, rtDayProfitChart, rtOrdersProfitChart;
var trOrdersRevenueChart, trDayProfitChart, realtimetargetSales = 0, traditionaltargetSales = 0;

var realtime = {
    init: function () {
        $('#p-csperf').hide();
        $('#diskbasedsubmitquery').hide();
        $('#perfsummary').hide();
        $('#getcireport').toggleClass('btn-success').html('Order Count <span class="badge" id="main-ordercount">0</span>');
        realtime.initiateHubs();
        realtime.rendergraph();
    },

    rendergraph: function () {
        var rtOrdersRevenueChartOptions = {
            chart: {
                renderTo: 'rt-ordersrevenue',
                height: 250,
                width: 350
            },
            subtitle: {
                text: ' ',
            },
            yAxis: {
                title: {
                    text: 'Revenue in $'
                }
            },
            series: [
                {
                    name: 'Hours',
                    data: [],
                    color: inmemoryColor
                }]
        };
        rtOrdersRevenueChart = new Highcharts.Chart(jQuery.extend(true, {}, defaultBarChart, rtOrdersRevenueChartOptions));

        var trOrdersRevenueChartOptions = {
            chart: {
                renderTo: 'tr-ordersrevenue',
                height: 250,
                width: 350
            },
            subtitle: {
                text: ' ',
            },
            yAxis: {
                title: {
                    text: 'Revenue in $'
                }
            },
            series: [
                {
                    name: 'Hours',
                    data: [],
                    color: diskbasedColor
                }]
        };
        trOrdersRevenueChart = new Highcharts.Chart(jQuery.extend(true, {}, defaultBarChart, trOrdersRevenueChartOptions));

        trDayProfitChart = new Highcharts.Chart({
            chart: {
                renderTo: 'tr-dayprofit',
                margin: [0, 0, 0, 0],
                backgroundColor: null,
                height: 160,
                plotBackgroundColor: 'none'
            },
            title: {
                text: null
            },
            tooltip: {
                formatter: function () {
                    return this.point.name + ': ' + this.y + ' %';
                }
            },
            series: [
                {
                    borderWidth: 2,
                    borderColor: '#F1F3EB',
                    shadow: false,
                    type: 'pie',
                    name: 'Elapsed Time',
                    innerSize: '0%',
                    data: [],
                    dataLabels: {
                        enabled: false,
                        color: '#000000',
                        connectorColor: '#000000'
                    }
                }]
        });

        var rtOrdersProfitChartOptions = {
            chart: {
                renderTo: 'rt-ordersprofit',
                height: 250,
                width: 550
            },
            subtitle: {
                text: '',
            },
            yAxis: {
                title: {
                    text: 'Revenue in $'
                }
            },
            series: [
                {
                    name: 'Minutes',
                    data: [],
                    color: inmemoryColor
                }]
        };
        rtOrdersProfitChart = new Highcharts.Chart(jQuery.extend(true, {}, defaultLineChart, rtOrdersProfitChartOptions));

        rtDayProfitChart = new Highcharts.Chart({
            chart: {
                renderTo: 'rt-dayprofit',
                margin: [0, 0, 0, 0],
                backgroundColor: null,
                height : 160,
                plotBackgroundColor: 'none'
            },
            title: {
                text: null
            },
            tooltip: {
                formatter: function () {
                    return this.point.name + ': ' + this.y + ' %';
                }
            },
            series: [
                {
                    borderWidth: 2,
                    borderColor: '#F1F3EB',
                    shadow: false,
                    type: 'pie',
                    name: 'Elapsed Time',
                    innerSize: '0%',
                    data: [],
                    dataLabels: {
                        enabled: false,
                        color: '#000000',
                        connectorColor: '#000000'
                    }
                }]
        });
    },

    initiateHubs: function () {

        realtimeHub = $.connection.realTimeAnalyticsHub;

        realtimeHub.client.sendOrderCount = function (dayProfit) {
            $('#main-ordercount').text(dayProfit);
        };

        $('#tr-runetl').on('click', function (oaModels) {
            $('#tr-runetl').text('Running...');
            $.ajax({
                url: "/Home/executeetl",
                dataType: "json",
                cache: false,
                contentType: 'application/json; charset=utf-8',
                type: "POST",
                success: function (result) {
                    $('#tr-runetl').text('Run ETL');
                }, error: function (result) {
                    $('#tr-runetl').text('Run ETL');
                }
            });
        });

        $('#rt-analyzesales').on('click', function (oaModels) {
            var categories = [], data = [], lastMinVal = 0, total = 0;
            $.ajax({
                url: "/Home/getoperationalanalytics",
                dataType: "json",
                data: JSON.stringify({ flag: 1 }),
                cache: false,
                contentType: 'application/json; charset=utf-8',
                type: "POST",
                success: function (result) {
                    var oaModels = result.oaModel;
                    var trdayProfit = result.trdayProfit;
                    var rtdayProfit = result.rtdayProfit;
                    var ordercount = result.orderCount;
                    //OA//////////////////////////////////////////////////////////
                    $.each(oaModels, function () {
                        lastMinVal = this.OrderRevenue;
                        total = total + this.OrderRevenue;
                        categories.push(this.OrderMinute);
                        data.push(this.OrderRevenue);
                    }
                    );
                    var avgValue = total / oaModels.length;
                    rtOrdersRevenueChart.setTitle(null, { text: '' });
                    rtOrdersRevenueChart.xAxis[0].setCategories(categories);
                    rtOrdersRevenueChart.series[0].setData(data);
                    //Day Profit//////////////////////////////////////////////////////////
                    data = [];
                    if (realtimetargetSales == 0) {
                        realtimetargetSales = trdayProfit * 2;
                    }
                    if ((realtimetargetSales - trdayProfit) < (realtimetargetSales * 0.1)) {
                        realtimetargetSales = trdayProfit * 2;
                    }
                    $('#rt-span-dayprofit').text('$' + rtdayProfit.format());
                    $('#rt-span-salestarget').text('$' + realtimetargetSales.format());
                    var profitPer = Math.round((rtdayProfit / realtimetargetSales) * 100).format();
                    $('#rt-span-dayprofitperc').text( profitPer + '%');
                    data.push({ name: 'Profit', y: parseFloat(profitPer), color: inmemoryColor });
                    data.push({ name: 'Target', y: parseFloat(100 - profitPer), color: 'transparent' });
                    rtDayProfitChart.series[0].setData(data);
                    //Order Count////////////////////////////////////////////////////////////
                    $('#rt-ordercount').text(ordercount);
                    //Orders Revenue////////////////////////////////////////////////////////////
                    categories = []; data = []; lastMinVal = 0; total = 0;
                    var oaModelsMin = result.ordersrevenuepermin;
                    $.each(oaModelsMin, function () {
                        lastMinVal = this.OrderRevenue;
                        total = total + this.OrderRevenue;
                        categories.push(this.OrderMinute);
                        data.push(this.OrderRevenue);
                        }
                    );
                    var avgValue = total / oaModels.length;
                    rtOrdersProfitChart.setTitle(null, { text: 'Last Minute Revenue: <span style="font-size:16px">$' + lastMinVal.format() + '</span><br/>Average Revenue/min: <span style="font-size:16px">$' + avgValue.format() + '</span>' });
                    rtOrdersProfitChart.xAxis[0].setCategories(categories);
                    rtOrdersProfitChart.series[0].setData(data);
                },
                error: function () { }
            });
        });

        $('#tr-analyzesales').on('click', function (data) {
            var categories = [], data = [], lastMinVal = 0, total = 0;
            $.ajax({
                url: "/Home/getoperationalanalytics",
                dataType: "json",
                data: JSON.stringify({ flag: 0 }),
                cache: false,
                contentType: 'application/json; charset=utf-8',
                type: "POST",
                success: function (result) {
                    var oaModels = result.oaModel;
                    var dayProfit = result.trdayProfit;
                    var ordercount = result.orderCount;
                    //OA//////////////////////////////////////////////////////////
                    $.each(oaModels, function () {
                        lastMinVal = this.OrderRevenue;
                        total = total + this.OrderRevenue;
                        categories.push(this.OrderMinute);
                        data.push(this.OrderRevenue);
                    }
                );
                    var avgValue = total / oaModels.length;
                    trOrdersRevenueChart.setTitle(null, { text: '' });
                    trOrdersRevenueChart.xAxis[0].setCategories(categories);
                    trOrdersRevenueChart.series[0].setData(data);
                    //Day Profit//////////////////////////////////////////////////////////
                    data = [];
                    if (traditionaltargetSales == 0) {
                        traditionaltargetSales = dayProfit * 2;
                    }
                    if ((traditionaltargetSales - dayProfit) < (traditionaltargetSales * 0.1)) {
                        traditionaltargetSales = dayProfit * 2;
                    }
                   
                    $('#tr-span-dayprofit').text('$' + dayProfit.format());
                    $('#tr-span-salestarget').text('$' + traditionaltargetSales.format());

                    var profitPer = Math.round((dayProfit / traditionaltargetSales) * 100).format();
                    $('#tr-span-dayprofitperc').text(profitPer + '%');
                    data.push({ name: 'Profit', y: parseFloat(profitPer), color: diskbasedColor });
                    data.push({ name: 'Target', y: parseFloat(100 - profitPer), color: 'transparent' });
                    trDayProfitChart.series[0].setData(data);
                    //Order Count//////////////////////////////////////////////////////////
                    $('#tr-ordercount').text(ordercount);
                },
                error: function () { }
            });
        });

        $.connection.hub.logging = true;
        $.connection.hub.start().done(function () {
            console.log('realtime hub started');
        });
    }
};

realtime.init();
