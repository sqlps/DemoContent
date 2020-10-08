var chart, staticchart;
var diskbasedColor = '#ec971f';
var inmemoryColor = '#ec971f';
Highcharts.theme = {
    global: {
        useUTC: false
    },
    colors: ["#2b908f", "#90ee7e", "#f45b5b", "#7798BF", "#aaeeee", "#ff0066", "#eeaaee",
       "#55BF3B", "#DF5353", "#7798BF", "#aaeeee"],
    chart: {
        backgroundColor: {
            linearGradient: { x1: 0, y1: 0, x2: 1, y2: 1 },
            stops: [
               [0, '#2a2a2b'],
               [1, '#3e3e40']
            ]
        },
        style: {
            fontFamily: "'Unica One', sans-serif"
        },
        plotBorderColor: '#606063'
    },
    title: {
        style: {
            color: '#E0E0E3',
            textTransform: 'uppercase',
            fontSize: '20px'
        }
    },
    legend: {
        enabled: false
    },
    exporting: {
        enabled: false
    },
    subtitle: {
        style: {
            color: '#E0E0E3',
            textTransform: 'uppercase'
        }
    },
    xAxis: {
        gridLineColor: '#707073',
        labels: {
            style: {
                color: '#E0E0E3'
            }
        },
        lineColor: '#707073',
        minorGridLineColor: '#505053',
        tickColor: '#707073',
        title: {
            style: {
                color: '#A0A0A3'

            }
        }
    },
    yAxis: {
        gridLineColor: '#707073',
        labels: {
            style: {
                color: '#E0E0E3'
            }
        },
        lineColor: '#707073',
        minorGridLineColor: '#505053',
        tickColor: '#707073',
        tickWidth: 1,
        title: {
            style: {
                color: '#A0A0A3'
            }
        }
    },
    tooltip: {
        backgroundColor: 'rgba(0, 0, 0, 0.85)',
        style: {
            color: '#F0F0F0'
        }
    },
    plotOptions: {
        series: {
            dataLabels: {
                color: '#B0B0B3'
            },
            marker: {
                lineColor: '#333'
            }
        },
        boxplot: {
            fillColor: '#505053'
        },
        candlestick: {
            lineColor: 'white'
        },
        errorbar: {
            color: 'white'
        }
    },
    legend: {
        itemStyle: {
            color: '#E0E0E3'
        },
        itemHoverStyle: {
            color: '#FFF'
        },
        itemHiddenStyle: {
            color: '#606063'
        }
    },
    credits: {
        enabled:false
    },
    labels: {
        style: {
            color: '#707073'
        }
    },

    drilldown: {
        activeAxisLabelStyle: {
            color: '#F0F0F3'
        },
        activeDataLabelStyle: {
            color: '#F0F0F3'
        }
    },

    navigation: {
        buttonOptions: {
            symbolStroke: '#DDDDDD',
            theme: {
                fill: '#505053'
            }
        }
    },

    // scroll charts
    rangeSelector: {
        buttonTheme: {
            fill: '#505053',
            stroke: '#000000',
            style: {
                color: '#CCC'
            },
            states: {
                hover: {
                    fill: '#707073',
                    stroke: '#000000',
                    style: {
                        color: 'white'
                    }
                },
                select: {
                    fill: '#000003',
                    stroke: '#000000',
                    style: {
                        color: 'white'
                    }
                }
            }
        },
        inputBoxBorderColor: '#505053',
        inputStyle: {
            backgroundColor: '#333',
            color: 'silver'
        },
        labelStyle: {
            color: 'silver'
        }
    },

    navigator: {
        handles: {
            backgroundColor: '#666',
            borderColor: '#AAA'
        },
        outlineColor: '#CCC',
        maskFill: 'rgba(255,255,255,0.1)',
        series: {
            color: '#7798BF',
            lineColor: '#A6C7ED'
        },
        xAxis: {
            gridLineColor: '#505053'
        }
    },

    scrollbar: {
        barBackgroundColor: '#808083',
        barBorderColor: '#808083',
        buttonArrowColor: '#CCC',
        buttonBackgroundColor: '#606063',
        buttonBorderColor: '#606063',
        rifleColor: '#FFF',
        trackBackgroundColor: '#404043',
        trackBorderColor: '#404043'
    },

    // special colors for some of the
    legendBackgroundColor: 'rgba(0, 0, 0, 0.5)',
    background2: '#505053',
    dataLabelsColor: '#B0B0B3',
    textColor: '#C0C0C0',
    contrastTextColor: '#F0F0F3',
    maskColor: 'rgba(255,255,255,0.3)'
};
Highcharts.setOptions(Highcharts.theme);
var defaultAreaChart = {
    chart: {
        renderTo: 'perfchart11',
        type: 'area',
        backgroundColor: 'transparent',
        marginLeft: 60,
        marginRight: 3
    },
    title: {
        text: ''
    },
    subtitle: {
        text: ''
    },
    xAxis: {
        type: 'datetime',
        tickPixelInterval: 150,
        title: { text: 'Time', fontSize: '15px' },
        labels: { style: { fontSize: '15px' } }
    },
    yAxis: {
        labels: {
            formatter: function () {
                return this.value;
            }
        },
        title: {
            text: 'CPU %',
        },
        labels: { style: { fontSize: '15px' } }
    },
    series: [],
    credits: {
        enabled: false
    },
    legend: {
        align: 'right',
        verticalAlign: 'top',
        layout: 'vertical',
        x: 0,
        y: 50
    },
    tooltip: {
        formatter: function () {
            return '<b>' + this.series.name + '</b><br/>' +
                Highcharts.dateFormat('%Y-%m-%d %H:%M:%S', this.x) + '<br/>' +
                Highcharts.numberFormat(this.y, 2);
        }
    },
    plotOptions: {
        spline: {
            dataLabels: {
                enabled: true
            },
            marker: {
                enabled: true,
            }
        }
    },
    tooltip: {
        enabled: true
    }
};
var defaultSplineChart = {
    chart: {
        renderTo: 'perfchart11',
        type: 'spline',
        height: 250,
        backgroundColor: 'transparent',
        width: 538
    },
    title: {
        text: ''
    },
    subtitle: {
        text: ''
    },
    xAxis: {
        type: 'datetime',
        tickPixelInterval: 150,
        title: {
            text : ''
        }
    },
    yAxis: {
        labels: {
            formatter: function () {
                return this.value;
            }
        },
        title: {
            text : ''
        }
    },
    series: [],
    credits: {
        enabled: false
    },
    legend: {
        align: 'right',
        verticalAlign: 'top',
        layout: 'vertical',
        x: 0,
        y: 100
    },
    tooltip: {
        formatter: function () {
            return '<b>' + this.series.name + '</b><br/>' +
                Highcharts.dateFormat('%Y-%m-%d %H:%M:%S', this.x) + '<br/>' +
                Highcharts.numberFormat(this.y, 2);
        }
    },
    plotOptions: {
        spline: {
            dataLabels: {
                enabled: true
            },
            marker: {
                enabled: true,
            }
        }
    },
    tooltip: {
        enabled: true
    }
};
var defaultXYChart = {
    chart: {
        renderTo: 'perfchart21',
        zoomType: 'xy',
        height: 250,
        backgroundColor: 'transparent',
        animation: Highcharts.svg
    },
    title: {
        text: ''
    },
    subtitle: {
        text: ''
    },
    xAxis: {
        title : {text : 'Time'},
        type: 'datetime',
        crosshair: true
    },
    yAxis: [{ // Primary yAxis
        labels: {
            format: '{value}',
            style: {
                color: Highcharts.getOptions().colors[1]
            }
        },
        title: {
            text: 'Sessions',
            style: {
                color: Highcharts.getOptions().colors[1]
            }
        },
        opposite: true

    }, { // Secondary yAxis
        gridLineWidth: 0,
        title: {
            text: 'Requests',
            style: {
                color: Highcharts.getOptions().colors[0]
            }
        },
        labels: {
            format: '{value}',
            style: {
                color: Highcharts.getOptions().colors[0]
            }
        }

    }],
    tooltip: {
        shared: true
    },
    legend: {
        layout: 'vertical',
        align: 'left',
        x: 80,
        verticalAlign: 'top',
        y: 55,
        floating: true,
        enabled :true,
        backgroundColor: (Highcharts.theme && Highcharts.theme.legendBackgroundColor) || '#FFFFFF'
    },
    credits: {
        enabled: false
    },
    series: [{
        name: 'Requests',
        type: 'column',
        yAxis: 0,
        data: [],
        tooltip: {
            valueSuffix: ''
        }

    }, {
        name: 'Exceptions',
        type: 'spline',
        yAxis: 1,
        data: [],
        marker: {
            enabled: false
        },
        dashStyle: 'shortdot',
        tooltip: {
            valueSuffix: ''
        }
    }]
}
var defaultPieChart = {
    chart: {
        plotBackgroundColor: null,
        plotBorderWidth: null,
        plotShadow: false,
        backgroundColor: 'transparent',
        type: 'pie'
    },
    title: {
        text: ''
    },
    tooltip: {
        pointFormat: '{series.name}: <b>{point.percentage:.1f}%</b>'
    },
    plotOptions: {
        pie: {
            allowPointSelect: true,
            cursor: 'pointer',
            dataLabels: {
                enabled: true,
                format: '<b>{point.name}</b>: {point.percentage:.1f} %',
                style: {
                    color: (Highcharts.theme && Highcharts.theme.contrastTextColor) || 'black'
                },
                connectorColor: 'silver'
            }
        }
    },
    series: [{
        name: 'Metrics',
        data: []
    }],
    credits: {
        enabled: false
    }
};
var defaultBarChart = {
    chart: {
        type: 'column',
        backgroundColor: 'transparent'
    },
    title: {
        text: '',
        style: { 'text-transform': 'none' }
    },
    xAxis: {
        categories: [],
        type: 'datetime',
        tickPixelInterval: 150,
        title: { text: 'Time' },
        labels: {
            style: {
                color: '#fff',
                fontSize: '15px'
            }
        }
    },
    scrollbar: {
        enabled: true
    },
    yAxis: {
        title: {
            text: 'Sales'
        },
        labels: { style: { fontSize: '15px' } }
    },
    legend: {
        enabled: true
    },
    tooltip: {
        formatter: function () {
            var value = this.y.format();
            return '<b>Value: $' + value + '</b><br/>';
        }
    },
    plotOptions: {
        column: {
            cursor: 'pointer',
            dataLabels: {
                enabled: true
            }
        }
    },
    credits: {
        enabled: false
    },
    series: [{
        name: '',
        data: [],
        dataLabels: {
            enabled: false,
            formatter: function () {
                return '$ ' + this.y.format();
            }
        },
        color: '#df7c2e'
    }]
};
var defaultLineChart = {
    chart:{
        renderTo: 'tr-ordersrevenue',
        type: 'line',
        animation: Highcharts.svg,
        height: 250,
        backgroundColor: 'transparent',
        width: 500
    },
    title: {
        text: '',
        x: -20, //center,
        backgroundColor: 'transparent'
    },
    subtitle: {
        text: '',
        x: -20
    },
    xAxis: {
        categories: []
    },
    yAxis: {
        title: {
            text: ''
        },
        plotLines: [{
            value: 0,
            width: 1,
            color: diskbasedColor
        }]
    },
    tooltip: {
        formatter: function () {
            return 'Revenue: $' + this.y.format() + ' in ' + this.point.category + 'th Minute';
        }
    },
    legend: {
        enabled : true
    },
    series: [
        {
            name: 'Minute',
            data: []
        }]
};
var defaultPyramidChart = {
    chart: {
        type: 'pyramid',
        renderTo: 'rt-dayprofit',
        backgroundColor: 'transparent',
        height: 200
    },
    title: {
        text: '',
        x: -50
    },
    tooltip: {
        formatter: function () {
            return 'Day Profit: $' + this.y.format();
        }
    },
    plotOptions: {
        pyramid: {
            dataLabels: {
                enabled: false,
            }
        }
    },
    legend: {
        enabled: false
    },
    series: [{
        name: 'Day Profit',
        data: []
    }]
};
Number.prototype.format = function (n, x) {
    var re = '\\d(?=(\\d{' + (x || 3) + '})+' + (n > 0 ? '\\.' : '$') + ')';
    return this.toFixed(Math.max(0, ~~n)).replace(new RegExp(re, 'g'), '$&,');
};
$(document).ready(function () {
    var pathName = window.location.pathname;
    $('#mainmenu li#' + menuSelected).toggleClass('active');
    $(window).resize(function () {
        if (this.resizeTO) clearTimeout(this.resizeTO);
        this.resizeTO = setTimeout(function () {
            // resizeEnd call function with pass context body
            adjustGraph.call($('body'));

        }, 500);
    });
    if (pathName.length == 1) {
        $('#mainmenu li#menu-dashboard').toggleClass('active');
        return;
    }
    var menuSelected = 'menu-' + pathName.split('/')[2];

   
});
$(window).unload(function () { $.connection.hub.stop(); });

$(function () {
    /**
     * Adjust size for hidden charts
     * @param chart highcharts
     */
    function adjustGraph(chart) {
        
        try {
            if (typeof (chart === 'undefined' || chart === null) && this instanceof jQuery) { // if no obj chart and the context is set
               
                this.find('.chart-wrapper:visible').each(function () { // for only visible charts container in the curent context
                    $container = $(this); // context container
                    $container.find('div[id^="diskbased-"]').each(function () { // for only chart
                        $chart = $(this).highcharts(); // cast from JQuery to highcharts obj
                        $chart.setSize($container.width(), $container.height(), doAnimation = true); // adjust chart size with animation transition
                    });
                    $container.find('div[id^="inmemory-"]').each(function () { // for only chart
                        $chart = $(this).highcharts(); // cast from JQuery to highcharts obj
                        $chart.setSize($container.width(), $container.height(), doAnimation = true); // adjust chart size with animation transition
                    });
                    $container.find('div[id^="d-p"]').each(function () { // for only chart
                        $chart = $(this).highcharts(); // cast from JQuery to highcharts obj
                        $chart.setSize($container.width(), $container.height(), doAnimation = true); // adjust chart size with animation transition
                    });
                    $container.find('div[id^="i-p"]').each(function () { // for only chart
                        $chart = $(this).highcharts(); // cast from JQuery to highcharts obj
                        $chart.setSize($container.width(), $container.height(), doAnimation = true); // adjust chart size with animation transition
                    });
                });
            } else {
                chart.setSize($('.chart-wrapper:visible').width(), $container.height(), doAnimation = true); // if chart is set, adjust
            }
        } catch (err) {
            // do nothing
        }
    }

    $(window).resize(function () {
        if (this.resizeTO) clearTimeout(this.resizeTO);
        this.resizeTO = setTimeout(function () {
            // resizeEnd call function with pass context body
            adjustGraph.call($('body'));
        }, 500);
    });

    $('a[data-toggle="tab"]').on('shown.bs.tab', function (e) {
        var isChart = $(this).attr('data-chart');
        var target = $(this).attr('href');
        if (isChart) {
            // call functio inside context target
            adjustGraph.call($(target));
        }
    });

    $('a[data-toggle="collapse"]').on('click', function (e) {
        var isChart = $(this).attr('data-chart');
        var target = $(this).attr('href');
        if (isChart) {
            // call functio inside context target
            setTimeout(function () {
                // resizeEnd call function with pass context body
                adjustGraph.call($(target));
            },200);
        }
    });
});
