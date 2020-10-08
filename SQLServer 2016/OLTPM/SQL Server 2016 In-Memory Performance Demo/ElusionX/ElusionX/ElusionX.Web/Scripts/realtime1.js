//Orange Color : #ec971f
var realTimeV1Hub, timeCounter = 0, users = 50, yoysalesticktockHandler, oltptimeCounter, oltpTimeTickerdup,
    iterations = 50, numberOfOrders = 200, bothCounter = 0, oltpTimeTicker, rtoaTimeTicker, rtoaStarted = false, oltpStarted = false, yoysales = false;
var realTimeData = { oltp: { cpu: [] }, rtoa: { cpu: [] } };

var realtimev1 = {
    init: function () {
        $('#p-csperf').hide();
        $('#diskbasedsubmitquery').hide();
        $('#perfsummary').hide();
        $('#getcireport').hide();
        realtimev1.initiateHubs();
        realtimev1.rendergraph();
        realtimev1.getRTOASettings();
    },

    rendergraph: function (data, header) {
        var years = [], sales = [];
        if (data) {
            $.each(data, function () {
                years.push(this.Year);
                sales.push(this.Price);
            })
        }
        $('#graphcontainer').highcharts({
            chart: {
                type: 'column',
                backgroundColor: 'transparent',
                height: 300
            },
            title: {
                text: header
            },
            subtitle: {
                text: ''
            },
            xAxis: {
                categories: years,
                crosshair: true,
                title: { text: 'Time' }
            },
            yAxis: {
                min: 0,
                title: {
                    text: 'Total Amount'
                },
                labels: { style: { fontsize: '16px' } }
            },
            tooltip: {
                headerFormat: '<span style="font-size:10px">{point.key}</span><br/>',
                pointFormat: '<span style="color:{series.color};padding:0">{series.name}: </span>' +
                    '<span style="padding:0"><b>$ {point.y:.1f}</b></span>',
                footerFormat: '</table>',
                shared: true,
                useHTML: true
            },
            plotOptions: {
                column: {
                    pointPadding: 0.2,
                    borderWidth: 0
                }
            },
            series: [{
                name: 'Sales',
                data: sales,
                color: '#df7c2e'
            }]
        });
    },

    getRTOASettings: function () {
        $.ajax({
            url: "/appconfig/getrtoasettings",
            contentType: 'application/json; charset=utf-8',
            cache: false,
            type: "GET",
            success: function (result) {
                if (result.data) {
                    users = result.data.NumberOfUsers;
                    iterations = result.data.Iterations;
                    numberOfOrders = result.data.NumberOfOrders;
                }
            },
            error: function () { }
        });
    },

    initiateHubs: function () {
        realTimeV1Hub = $.connection.realTimeAnalyticsHub;

        realTimeV1Hub.client.sendOLTPCPUMetrics = function (oltpMetrics) {
            if (oltpStarted || rtoaStarted) {
                if (oltpMetrics.CPU > 0)
                    realTimeData.oltp.cpu.push(oltpMetrics.CPU);
                if (rtoaStarted) {
                    $('#results-both-oltp-orders').text(oltpMetrics.Orders);
                    $('#oltp-orders').text(oltpMetrics.Orders);
                    if (oltpMetrics.Orders >= (users * iterations * numberOfOrders)) {
                        clearInterval(oltpTimeTicker);
                        clearInterval(oltpTimeTickerdup);
                        $('#div-results-both-oltp-cpu').show();
                        $('#results-both-oltp-cpu').text(realtimev1.getAvgCPU(realTimeData.oltp.cpu) + ' %');
                        rtoaStarted = false;
                        realTimeData = { oltp: { cpu: [] }, rtoa: { cpu: [] } };
                    }
                } else {
                    $('#oltp-orders').text(oltpMetrics.Orders);
                    if (oltpMetrics.Orders >= (users * iterations * numberOfOrders)) {
                        clearInterval(oltpTimeTicker);
                        $('#div-oltp-cpu').show();
                        $('#oltp-cpu').text(realtimev1.getAvgCPU(realTimeData.oltp.cpu) + '%');
                        $('#results-oltp-orders').text($('#oltp-orders').text());
                        $('#results-oltp-timetaken').text($('#oltp-timetaken').text());
                        $('#results-oltp-cpu').text($('#oltp-cpu').text());
                        oltpStarted = false;
                        realTimeData = { oltp: { cpu: [] }, rtoa: { cpu: [] } };
                    }
                }
            }
        };

        realTimeV1Hub.client.sendRTOACPUMetrics = function (rtoaMetrics) {
            if (rtoaStarted || yoysales) {
                if (rtoaMetrics.CPU > 0)
                    realTimeData.rtoa.cpu.push(rtoaMetrics.CPU);
            }
        };

        $('#btnplaceorders').on('click', function () {
            oltpStarted = true;
            $('#btnplaceorders').text('Running...');
            oltptimeCounter = 0;
            $('#div-oltp-cpu').hide();
            clearInterval(oltptimeCounter);
            oltpTimeTicker = setInterval(realtimev1.ticktock, 1000, ['#oltp-timetaken', ' s', oltptimeCounter]);
            $.ajax({
                url: "/Home/executertoa?queryType=OLTP",
                dataType: "json",
                cache: false,
                contentType: 'application/json; charset=utf-8',
                type: "GET",
                success: function (result) {
                }, error: function (result) {
                    console.log("error:" + result.responseText);
                }
            });
            $('#btnplaceorders').text('Place Orders');
        });

        $('#btnyoysales').on('click', function () {
            yoysales = true;
            $('#btnyoysales').text('Running...');
            timeCounter = 0;
            $('#div-rtoa-cpu').hide();
            $('#rtoa-timetaken').text("...");
            $('#rtoa-cpu').text("...");
            $('#rtoa-iterations').text("...");
            var fadeAnimation = setInterval(function () {
                $('#rtoa-timetaken,#rtoa-cpu,#rtoa-iterations').fadeOut(500);
                $('#rtoa-timetaken,#rtoa-cpu,#rtoa-iterations').fadeIn(500);
            }, 1000);
            var startTime = Date.now();
            $.ajax({
                url: "/Home/executeyoysales?queryType=0",
                dataType: "json",
                cache: false,
                contentType: 'application/json; charset=utf-8',
                type: "GET",
                success: function (result) {
                    clearInterval(fadeAnimation);
                    realtimev1.rendergraph(result.data, 'CCI on Disk-based');
                    var endTime = Date.now();
                    $('#rtoa-timetaken').text(((endTime - startTime)) + " ms")
                    $('#div-rtoa-cpu').show();
                    $('#rtoa-cpu').text(realtimev1.getAvgCPU(realTimeData.rtoa.cpu) + ' %');
                    $('#rtoa-iterations').text(result.iterations);
                    $('#results-rtoa-timetaken').text($('#rtoa-timetaken').text());
                    $('#results-rtoa-cpu').text($('#rtoa-cpu').text());
                    $('#results-rtoa-iterations').text($('#rtoa-iterations').text());
                    yoysales = false;
                }, error: function (result) {
                    console.log("error:" + result.responseText);
                }
            });
            $('#btnyoysales').text('YOY Sales');
        });

        $('#btnrtoaplaceorders').on('click', function () {
            rtoaStarted = true;
            oltptimeCounter = 0;
            //$('#div-results-both-oltp-cpu').hide();
            clearInterval(oltpTimeTicker);
            clearInterval(oltpTimeTickerdup);
            oltpTimeTicker = setInterval(realtimev1.ticktock, 1000, ['#results-both-oltp-timetaken', ' s', oltptimeCounter]);
            oltpTimeTickerdup = setInterval(realtimev1.ticktock, 1000, ['#oltp-timetaken', ' s', oltptimeCounter]);
            //OLTP CALL
            $.ajax({
                url: "/Home/executertoa?queryType=RTOA",
                dataType: "json",
                cache: false,
                contentType: 'application/json; charset=utf-8',
                type: "GET",
                success: function (result) {
                }, error: function (result) {
                    console.log("error:" + result.responseText);
                }
            });
        });

        $('#btnrtoayoysales').on('click', function () {
            rtoaStarted = true;
            //RTOA Call
            //$('#div-results-both-rtoa-cpu').hide();
            $('#rtoa-timetaken').text("...");
            $('#rtoa-cpu').text("...");
            $('#rtoa-iterations').text("...");
            $('#results-both-rtoa-timetaken').text("...");
            $('#results-both-rtoa-cpu').text("...");
            $('#results-both-rtoa-iterations').text("...");
            realtimev1.rendergraph([], 'CCI on In-Memory');
            var fadeAnimation = setInterval(function () {
                $('#rtoa-timetaken,#rtoa-cpu,#rtoa-iterations,#results-both-rtoa-timetaken,#results-both-rtoa-cpu,#results-both-rtoa-iterations').fadeOut(500);
                $('#rtoa-timetaken,#rtoa-cpu,#rtoa-iterations,#results-both-rtoa-timetaken,#results-both-rtoa-cpu,#results-both-rtoa-iterations').fadeIn(500);
            }, 1000);
            var startTime = Date.now();
            $.ajax({
                url: "/Home/executeyoysales?queryType=1",
                dataType: "json",
                cache: false,
                contentType: 'application/json; charset=utf-8',
                type: "GET",
                success: function (result) {
                    clearInterval(fadeAnimation);
                    realtimev1.rendergraph(result.data, 'CCI on In-Memory');
                    var endTime = Date.now();
                    $('#results-both-rtoa-timetaken').text(((endTime - startTime)) + " ms")
                    $('#div-results-both-rtoa-cpu').show();
                    $('#results-both-rtoa-cpu').text(realtimev1.getAvgCPU(realTimeData.rtoa.cpu) + ' %');
                    $('#results-both-rtoa-iterations').text(result.iterations);
                    //Copy to Step 2
                    $('#rtoa-timetaken').text($('#results-both-rtoa-timetaken').text());
                    $('#div-rtoa-cpu').show();
                    $('#rtoa-cpu').text($('#results-both-rtoa-cpu').text());
                    $('#rtoa-iterations').text($('#results-both-rtoa-iterations').text());
                }, error: function (result) {
                    console.log("error:" + result.responseText);
                }
            })
        });

        $.connection.hub.logging = true;
        $.connection.hub.start().done(function () {
            console.log('realtimev1 hub started');
        });
    },

    getAvgCPU: function (cpuArray) {
        var cpuSum = 0;
        $.each(cpuArray, function () {
            cpuSum += this;
        });
        var result = (cpuSum / cpuArray.length).toFixed(2);
        return isNaN(result) ? '< 0' : result;
    },

    ticktock: function (element) {
        $(element[0]).text(++element[2] + ' ' + element[1]);
    },
};
realtimev1.init();
