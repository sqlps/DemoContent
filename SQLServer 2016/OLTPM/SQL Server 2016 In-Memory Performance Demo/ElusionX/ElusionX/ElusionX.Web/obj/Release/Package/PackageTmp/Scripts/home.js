/*************************** Global Variables *************************************************/
var latchWaitsPerSecChart, diskBasedPieChart, requests = [], sessions = [], inmemoryStartDate,
    diskBasedStartDate, counter = 0, clearDiskBasedInterval, clearInMemoryInterval, inMemoryLatchWaitsPerSecChart,
    inMemoryPieChart, inmemoryrequests = [], inmemorysessions = [], inmemorycounter = 0, inmemoryhub,
    diskbasedhub, diskbasedhubstopped = false, inmemoryhubstopped = false, diskbasedCPU = [], inmemoryCPU = [],
    diskBasedCPUChart, inmemoryCPUChart, diskbasedprofitlosschart, diskbasedavgvalues = [], diskbasedavgvalueChart,
    inmemoryprofitlosschart, inmemoryavgvalues = [], inmemoryavgvalueChart, avgpersec = "Avg. Per Sec";
/*************************** Global Variables *************************************************/
var elusionX = {
    diskBased: {
        init: function () {
            $('#getcireport').hide();
            $("#diskbasedsubmitquery").on('click', elusionX.diskBased.executeDiskBasedQuery);
            $('#perfsummary').hide();
            $('#technicaltab').addClass('active in');
            $('#rowcount, #ordersperuser').on('change', function () {
                var rowcount = parseInt($('#rowcount').val());
                var ordersperuser = parseInt($('#ordersperuser').val());
                $('#totalorders').text(rowcount * ordersperuser);
            });
            //$('#perfsummary').show();
            //$('#perfsummary').on('click',
            //elusionX.perfSummary.renderPerfSummary);
            $('#businesstab').on('click', function () {
                $(window).resize();
            })
        },

        renderLatchWaitsChart: function () {
            var latchWaitsPerSecChartOptions = {
                chart: {
                    renderTo: 'diskbased-requests', marginLeft: 80
                }, xAxis: {
                    title: { text: 'Time' }
                },
                yAxis: {
                    title: {
                        text: 'Sessions'
                    }
                }, tooltip: {
                    formatter: function () {
                        var value = this.y.format();
                        return '<b>Sessions: ' + value + '</b><br/>';
                    }
                },
                series: [{
                    name: 'Sessions',
                    color: diskbasedColor
                }]
            };
            latchWaitsPerSecChart = new Highcharts.Chart(jQuery.extend(true, {}, defaultAreaChart, latchWaitsPerSecChartOptions));
        },

        renderCPUChart: function () {
            var cpumetrics = {
                chart: {
                    renderTo: 'diskbased-cpu', marginLeft: 80
                },
                yAxis: {
                    max: 100
                },
                series: [{
                    name: '%CPU Usage',
                    data: [],
                    color: diskbasedColor
                }
                ]
            }
            diskBasedCPUChart = new Highcharts.Chart(jQuery.extend(true, {}, defaultAreaChart, cpumetrics));
        },

        renderBusinessCharts: function () {
            var profitloss = {
                chart: {
                    renderTo: 'diskbased-profitloss',
                },
                xAxis: {
                    title: { text: '' },
                    categories: ['Expected', 'Total', 'Loss']
                },
                plotOptions: {
                    column: {
                        dataLabels: {
                            enabled: true,
                        }
                    }
                },
                series: [{
                    name: 'Revenue in $',
                    type: 'column',
                    yAxis: 0,
                    data: [],
                    dataLabels: {
                        enabled: true
                    },
                    tooltip: {
                        valueSuffix: ''
                    }
                }]
            }
            diskbasedprofitlosschart =
                new Highcharts.Chart(jQuery.extend(true, {}, defaultBarChart, profitloss));
            var avgvalue = {
                chart: {
                    renderTo: 'diskbased-avgvalue', marginLeft: 80
                },
                xAxis: {
                    title: { text: 'Time' }
                },
                yAxis: {
                    title: {
                        text: 'Sales'
                    }
                },
                series: [
                    {
                        name: 'avg. value per sec',
                        color: diskbasedColor,
                        data: [],
                    }
                ]
            }
            diskbasedavgvalueChart =
                new Highcharts.Chart(jQuery.extend(true, {}, defaultAreaChart, avgvalue));
        },

        executeDiskBasedQuery: function () {
            var crowCount = parseInt($('#rowcount').val());
            var orders = parseInt($('#ordersperuser').val());
            $.ajax({
                url: "/Home/executequery",
                dataType: "json",
                data: JSON.stringify({ orderCount: orders, users: crowCount, queryFlag: 0 }),
                contentType: 'application/json; charset=utf-8',
                cache: false,
                type: "POST",
                success: function () {
                    elusionX.diskBased.initiateHubs();
                    elusionX.diskBased.onDiskBasedQuerySuccess();
                },
                error: function () { }
            });
            return false;
        },

        onDiskBasedQuerySuccess: function () {
            if (!$('#businesstab').hasClass('active')) {
                $('#technicaltab').addClass('active in');
            }
            $('#tabsheader').css('visibility', 'visible');
            $('#tabscontent').css('visibility', 'visible');
            elusionX.diskBased.renderLatchWaitsChart();
            elusionX.diskBased.renderDiskBasedQueryStatus();
            elusionX.diskBased.diskBasedTickTock();
            elusionX.diskBased.renderCPUChart();
            elusionX.diskBased.renderBusinessCharts();
            clearDiskBasedInterval = setInterval(elusionX.diskBased.diskBasedTickTock, 1000);
            $('#step1').addClass('complete');
        },

        initiateHubs: function () {
            diskbasedhub = $.connection.diskBasedHub;

            // Create a function that the hub can call back to display messages.
            diskbasedhub.client.sendTechnicalMetrics = function (diskBasedMetrics) {
                $('#diskbased-batchrequests').text(diskBasedMetrics.BatchRequests);
                $('#diskbased-latchwaits').text(diskBasedMetrics.LatchWaits);
                $('#diskbased-sessions').text(diskBasedMetrics.Sessions);
                $('#diskbased-contextswitches').text(diskBasedMetrics.Requests.format());
                var date = new Date();
                sessions.push({
                    x: date.getTime(), y: diskBasedMetrics.Sessions
                });
                diskbasedCPU.push({ x: (new Date()).getTime(), y: diskBasedMetrics.CPU });
                latchWaitsPerSecChart.series[0].setData(sessions);
                diskBasedCPUChart.series[0].setData(diskbasedCPU);
                elusionX.perfSummary.disk.cpu.push({ x: (new Date()).getTime(), y: diskBasedMetrics.CPU });
                if (!diskbasedhubstopped) {
                    if (diskBasedMetrics.BatchRequests > 0) {
                        elusionX.perfSummary.disk.batchrequests.push({ x: (new Date()).getTime(), y: diskBasedMetrics.BatchRequests });
                    }
                    if (diskBasedMetrics.LatchWaits > 0) {
                        elusionX.perfSummary.disk.latchwaits.push({ x: (new Date()).getTime(), y: diskBasedMetrics.LatchWaits });
                    }
                    if (diskBasedMetrics.Requests > 0) {
                        elusionX.perfSummary.disk.requests.push({ x: (new Date()).getTime(), y: diskBasedMetrics.Requests });
                    }
                    if (diskBasedMetrics.Sessions > 0) {
                        elusionX.perfSummary.disk.sessions.push({ x: (new Date()).getTime(), y: diskBasedMetrics.Sessions });
                    }
                }
            }

            diskbasedhub.client.sendLoadEngineMetrics = function (loadMetrics) {
                var data = [];
                data.push({ name: 'Completed', y: loadMetrics.TotalCompleted, color: diskbasedColor });
                data.push({ name: 'Pending', y: loadMetrics.TotalLoad, color: '#3d3d3d' });
                $('#diskbased-exceptions').text(loadMetrics.Exceptions);
                if (loadMetrics.TotalCompleted < 100 && loadMetrics.TotalCompleted >= 0) {
                    diskBasedPieChart.series[0].setData(data);
                }
                if (!diskbasedhubstopped) {
                    // Order complete
                    if (loadMetrics.TotalCompleted == 100) {
                        setTimeout(function () {
                            diskbasedhubstopped = true;
                            $.connection.hub.stop();
                            console.log('diskbased hub stopped');
                            setTimeout(function () { }, 2000);
                            clearInterval(clearDiskBasedInterval);
                            $('#step2').removeClass('disabled');
                            $('#diskbasedsubmitquery').off('click', elusionX.diskBased.executeDiskBasedQuery);
                            elusionX.inmemory.init();
                            // Set Avg Values here
                            $('#diskbased-batchrequests').text(elusionX.diskBased.getAvgValue(elusionX.perfSummary.disk.batchrequests));
                            $('#diskbased-batchrequests-subtext').text(avgpersec);

                            $('#diskbased-contextswitches').text(elusionX.diskBased.getAvgValue(elusionX.perfSummary.disk.requests));
                            $('#diskbased-contextswitches-subtext').text(avgpersec);

                            $('#diskbased-latchwaits').text(elusionX.diskBased.getAvgValue(elusionX.perfSummary.disk.latchwaits));
                            $('#diskbased-latchwaits-subtext').text(avgpersec);

                            $('#diskbased-sessions').text(elusionX.diskBased.getAvgValue(elusionX.perfSummary.disk.sessions));
                            $('#diskbased-sessions-subtext').text(avgpersec);

                        }, 3000);
                        diskBasedPieChart.series[0].setData(data);
                    }
                }
            };

            diskbasedhub.client.sendBusinessMetrics = function (businessMetrics) {
                var profitlossData = [];
                profitlossData.push({ name: 'Total', y: businessMetrics.TotalOrderValue });
                profitlossData.push({ name: 'Revenue', y: businessMetrics.ProfitPercentage });
                profitlossData.push({
                    name: 'Loss',
                    y: businessMetrics.LossPercentage
                });
                diskbasedprofitlosschart.series[0].setData(profitlossData);
                $('#diskbased-users').text(businessMetrics.Users.format() + "/");
                $('#diskbased-totalorders').text(businessMetrics.TotalOrders.format());
                $('#diskbased-totalvalue').text(businessMetrics.TotalValue);
                $('#diskbased-avgtime').text(businessMetrics.AvgTimetakenPerOrder);
                $('#diskbased-failedorders').text(businessMetrics.FailedOrders.format());
                $('#diskbased-estimatedloss').text(businessMetrics.EstimatedLoss);
                $('#diskbased-totalusers').text(businessMetrics.TotalUsers.format());
                $('#diskbased-orders').text(businessMetrics.Orders.format() + "/");
                if (businessMetrics.AvgValue > 0) {
                    var date = new Date();
                    diskbasedavgvalues.push({ x: (date.getTime()), y: Math.round(businessMetrics.AvgValue) });
                    diskbasedavgvalueChart.series[0].setData(diskbasedavgvalues);
                }
                if (!diskbasedhubstopped) {
                    //load data to performance summary
                    elusionX.perfSummary.disk.users = businessMetrics.Users;
                    elusionX.perfSummary.disk.totalOrders = businessMetrics.Orders;
                    elusionX.perfSummary.disk.totalvalue = businessMetrics.TotalValue;
                    elusionX.perfSummary.disk.avgvalue = businessMetrics.AvgValue;
                    elusionX.perfSummary.disk.avgtimeperorder = businessMetrics.AvgTimetakenPerOrder;
                    elusionX.perfSummary.disk.estimatedloss = businessMetrics.EstimatedLoss;
                }
            }

            $.connection.hub.logging = true;
            $.connection.hub.start().done(function () {
                console.log('diskbase hub started');
            });
        },

        renderDiskBasedQueryStatus: function () {
            diskBasedPieChart = new Highcharts.Chart({
                chart: {
                    renderTo: 'load',
                    margin: [0, 0, 0, 0],
                    backgroundColor: null,
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
                        borderColor: diskbasedColor,
                        shadow: false,
                        type: 'pie',
                        name: 'Elapsed Time',
                        innerSize: '65%',
                        data: [],
                        dataLabels: {
                            enabled: false,
                            color: diskbasedColor,
                            connectorColor: diskbasedColor
                        }
                    }]
            });
        },

        diskBasedTickTock: function () {
            var clock = document.querySelector('digiclock');
            diskBasedStartDate = new Date(2016, 2, 6, 0, 0, counter, 0);
            var h = elusionX.diskBased.pad(diskBasedStartDate.getHours());
            var m = elusionX.diskBased.pad(diskBasedStartDate.getMinutes());
            var s = elusionX.diskBased.pad(diskBasedStartDate.getSeconds());
            var current_time = [h, m, s].join(':');
            if (clock) {
                clock.innerHTML = current_time;
                if (!diskbasedhubstopped) {
                    elusionX.perfSummary.disk.totaltime = current_time;
                }
            }
            ++counter;
        },

        getAvgValue: function (array) {
            var sum = 0;
            $.each(array, function () {
                sum += this.y;
            });
            var result = (sum / array.length).toFixed(0);
            return isNaN(result) ? '< 0' : result;
        },

        pad: function (x) {
            return x < 10 ? '0' + x : x;
        }
    },
    inmemory: {
        init: function () {
            $('#inmemory-technicaltab').addClass('active in');
            $('#diskbasedsubmitquery').off('click', elusionX.inmemory.executeInmemoryQuery);
            $("#diskbasedsubmitquery").on('click', elusionX.inmemory.executeInmemoryQuery);
        },

        renderCPUChart: function () {
            var cpumetrics = {
                chart: {
                    renderTo: 'inmemory-cpu', marginLeft: 80
                },
                yAxis: {
                    max: 100
                },
                series: [{
                    name: '%CPU Usage',
                    data: [],
                    color: inmemoryColor,
                    tooltip: ''
                }
                ]
            }
            inmemoryCPUChart = new Highcharts.Chart(jQuery.extend(true, {}, defaultAreaChart, cpumetrics));
        },

        renderBusinessCharts: function () {
            var profitloss = {
                chart: {
                    renderTo: 'inmemory-profitloss'
                },
                xAxis: {
                    categories: ['Expected', 'Total', 'Loss']
                },
                plotOptions: {
                    column: {
                        dataLabels: {
                            enabled: true,
                        }
                    }
                },
                series: [{
                    name: 'Revenue in $',
                    type: 'column',
                    yAxis: 0,
                    data: [],
                    dataLabels: {
                        enabled: true
                    },
                    tooltip: {
                        valueSuffix: ''
                    }
                }]
            }
            inmemoryprofitlosschart =
                new Highcharts.Chart(jQuery.extend(true, {}, defaultBarChart, profitloss));
            var avgvalue = {
                chart: {
                    renderTo: 'inmemory-avgvalue', marginLeft: 80
                }, series: [
                    {
                        name: 'avg. value per sec',
                        color: inmemoryColor,
                        data: [],
                    }
                ]
            }
            inmemoryavgvalueChart =
                new Highcharts.Chart(jQuery.extend(true, {}, defaultAreaChart, avgvalue));
        },

        renderLatchWaitsChart: function () {
            var inMemoryLatchWaitsPerSecChartOptions = {
                chart: {
                    renderTo: 'inmemory-requests', marginLeft: 80
                }, xaxis: {
                    title: { text: 'Time' }
                },
                yAxis: {
                    title: {
                        text: 'Sessions'
                    }
                }, tooltip: {
                    formatter: function () {
                        var value = this.y.format();
                        return '<b>Sessions: ' + value + '</b><br/>';
                    }
                },
                series: [{
                    name: 'Sessions',
                    color: inmemoryColor
                }]
            };
            inMemoryLatchWaitsPerSecChart =
            new Highcharts.Chart(jQuery.extend(true, {}, defaultAreaChart, inMemoryLatchWaitsPerSecChartOptions));
        },

        executeInmemoryQuery: function () {
            $('#scenario1title').text('In-Memory');
            var crowCount = parseInt($('#rowcount').val());
            var orders = parseInt($('#ordersperuser').val());
            $.ajax({
                url: "/Home/executequery",
                dataType: "json",
                data: JSON.stringify({ orderCount: orders, users: crowCount, queryFlag: 1 }),
                contentType: 'application/json; charset=utf-8',
                type: "POST",
                success: function () {
                    $('#technicaltab').hide();
                    $('#businesstab').hide();
                    $('#inmemory-technicaltab').removeAttr('style');
                    $('#inmemory-businesstab').removeAttr('style');
                    $('#technical').hide();
                    $('#business').hide();
                    $('#inmemory-technical').removeAttr('style');
                    $('#inmemory-business').removeAttr('style');
                    elusionX.inmemory.initiateHubs();
                    elusionX.inmemory.onInMemoryQuerySuccess();
                },
                error: function () { }
            });
            return false;
        },

        onInMemoryQuerySuccess: function () {
            $('#inmemory-tabcontent').css('visibility', 'visible');
            $('#inmemory-technicaltab').addClass('active in');
            $('#inmemory-technical').addClass('active in');
            $('#tabsheader').css('visibility', 'visible');
            elusionX.inmemory.renderLatchWaitsChart();
            elusionX.inmemory.renderInMemoryQueryStatus();
            elusionX.inmemory.inmemoryTickTock();
            elusionX.inmemory.renderCPUChart();
            elusionX.inmemory.renderBusinessCharts();
            clearInMemoryInterval = setInterval(elusionX.inmemory.inmemoryTickTock, 1000);
            $('#step2').addClass('complete');
        },

        initiateHubs: function () {
            inmemoryhub = $.connection.inMemoryHub;
            // Create a function that the hub can call back to display messages.
            inmemoryhub.client.sendInMemoryTechnicalMetrics = function (inmemoryBasedMetrics) {
                $('#inmemory-batchrequests').text(inmemoryBasedMetrics.BatchRequests);
                $('#inmemory-latchwaits').text(inmemoryBasedMetrics.LatchWaits);
                $('#inmemory-sessions').text(inmemoryBasedMetrics.Sessions);
                $('#inmemory-contextswitches').text(inmemoryBasedMetrics.Requests.format());
                //inmemoryrequests.push(inmemoryBasedMetrics.Requests);
                inmemorysessions.push({
                    x: (new Date()).getTime(), y: inmemoryBasedMetrics.Sessions
                });
                inMemoryLatchWaitsPerSecChart.series[0].setData(inmemorysessions);
                //inMemoryLatchWaitsPerSecChart.series[1].setData(inmemorysessions);
                inmemoryCPU.push({ x: (new Date()).getTime(), y: inmemoryBasedMetrics.CPU });
                inmemoryCPUChart.series[0].setData(inmemoryCPU);
                elusionX.perfSummary.inmemory.cpu.push({ x: (new Date()).getTime(), y: inmemoryBasedMetrics.CPU });
                if (!inmemoryhubstopped) {
                    if (inmemoryBasedMetrics.BatchRequests > 0) {
                        elusionX.perfSummary.inmemory.batchrequests.push({ x: (new Date()).getTime(), y: inmemoryBasedMetrics.BatchRequests });
                    }
                    if (inmemoryBasedMetrics.LatchWaits > 0) {
                        elusionX.perfSummary.inmemory.latchwaits.push({ x: (new Date()).getTime(), y: inmemoryBasedMetrics.LatchWaits });
                    }
                    if (inmemoryBasedMetrics.Requests > 0) {
                        elusionX.perfSummary.inmemory.requests.push({ x: (new Date()).getTime(), y: inmemoryBasedMetrics.Requests });
                    }
                    if (inmemoryBasedMetrics.Sessions > 0) {
                        elusionX.perfSummary.inmemory.sessions.push({ x: (new Date()).getTime(), y: inmemoryBasedMetrics.Sessions });
                    }
                }
            }

            inmemoryhub.client.sendInMemoryLoadEngineMetrics = function (loadMetrics) {
                if (isNaN(loadMetrics.TotalCompleted)) return;
                console.log('total completed' + loadMetrics.TotalCompleted);
                var inmemoryChartData = [];
                inmemoryChartData.push({ name: 'Completed', y: loadMetrics.TotalCompleted, color: inmemoryColor });
                inmemoryChartData.push({ name: 'Pending', y: loadMetrics.TotalLoad, color: '#3d3d3d' });
                $('#inmemory-exceptions').text(loadMetrics.Exceptions);
                if (loadMetrics.TotalCompleted < 100 && loadMetrics.TotalCompleted >= 0) {
                    inMemoryPieChart.series[0].setData(inmemoryChartData);
                }
                // Order complete
                if (loadMetrics.TotalCompleted == 100) {
                    setTimeout(function () {
                        $.connection.hub.stop();
                        console.log('inmmemory hub stopped');
                        setTimeout(function () { }, 3000);
                        if (!inmemoryhubstopped) {
                            inmemoryhubstopped = true;
                            clearInterval(clearInMemoryInterval);
                            $('#step2').addClass('complete');
                            $('#step3').removeClass('disabled');
                            $('#step3').addClass('complete');
                            $('#diskbasedsubmitquery').off('click', elusionX.inmemory.executeDiskBasedQuery);
                            $('#perfsummary').show();
                            $('#perfsummary').on('click',
                            elusionX.perfSummary.renderPerfSummary);

                            //Set Avg Values for Counters
                            $('#inmemory-batchrequests').text(elusionX.diskBased.getAvgValue(elusionX.perfSummary.inmemory.batchrequests));
                            $('#inmemory-batchrequests-subtext').text(avgpersec);

                            $('#inmemory-contextswitches').text(elusionX.diskBased.getAvgValue(elusionX.perfSummary.inmemory.requests));
                            $('#inmemory-contextswitches-subtext').text(avgpersec);

                            $('#inmemory-latchwaits').text(elusionX.diskBased.getAvgValue(elusionX.perfSummary.inmemory.latchwaits));
                            $('#inmemory-latchwaits-subtext').text(avgpersec);

                            $('#inmemory-sessions').text(elusionX.diskBased.getAvgValue(elusionX.perfSummary.inmemory.sessions));
                            $('#inmemory-sessions-subtext').text(avgpersec);
                        }
                    }, 3000);
                    inMemoryPieChart.series[0].setData(inmemoryChartData);
                }
            };

            inmemoryhub.client.sendInMemoryBusinessMetrics = function (businessMetrics) {
                var inmemoryprofitlossData = [];
                inmemoryprofitlossData.push({ name: 'Total', y: businessMetrics.TotalOrderValue });
                inmemoryprofitlossData.push({ name: 'Revenue', y: businessMetrics.ProfitPercentage });
                inmemoryprofitlossData.push({
                    name: 'Loss',
                    y: businessMetrics.LossPercentage
                });
                inmemoryprofitlosschart.series[0].setData(inmemoryprofitlossData);
                $('#inmemory-users').text(businessMetrics.Users.format() + "/");
                $('#inmemory-totalorders').text(businessMetrics.TotalOrders.format());
                $('#inmemory-totalvalue').text(businessMetrics.TotalValue);
                //$('#inmemory-avgvalue').text(businessMetrics.AvgValue);
                $('#inmemory-avgtime').text(businessMetrics.AvgTimetakenPerOrder);
                $('#inmemory-failedorders').text(businessMetrics.FailedOrders.format());
                $('#inmemory-estimatedloss').text(businessMetrics.EstimatedLoss);
                $('#inmemory-totalusers').text(businessMetrics.TotalUsers.format());
                $('#inmemory-orders').text(businessMetrics.Orders.format() + "/");
                if (businessMetrics.AvgValue > 0) {
                    inmemoryavgvalues.push({ x: (new Date()).getTime(), y: Math.round(businessMetrics.AvgValue) });
                    inmemoryavgvalueChart.series[0].setData(inmemoryavgvalues);
                }
                if (!inmemoryhubstopped) {
                    //load data to performance summary
                    elusionX.perfSummary.inmemory.users = businessMetrics.Users;
                    elusionX.perfSummary.inmemory.totalOrders = businessMetrics.Orders;
                    elusionX.perfSummary.inmemory.totalvalue = businessMetrics.TotalValue;
                    elusionX.perfSummary.inmemory.avgvalue = businessMetrics.AvgValue;
                    elusionX.perfSummary.inmemory.avgtimeperorder = businessMetrics.AvgTimetakenPerOrder;
                    elusionX.perfSummary.inmemory.estimatedloss = businessMetrics.EstimatedLoss;
                }
            }

            $.connection.hub.start().done(function () {
                console.log('hub started');
            });
        },

        renderInMemoryQueryStatus: function () {
            inMemoryPieChart = new Highcharts.Chart({
                chart: {
                    renderTo: 'space',
                    margin: [0, 0, 0, 0],
                    backgroundColor: null,
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
                        borderColor: diskbasedColor,
                        shadow: false,
                        type: 'pie',
                        name: 'Elapsed Time',
                        innerSize: '65%',
                        data: [],
                        dataLabels: {
                            enabled: false,
                            color: inmemoryColor,
                            connectorColor: inmemoryColor
                        }
                    }]
            });
        },

        inmemoryTickTock: function () {
            var clock = document.querySelector('digiclock1');
            inmemoryStartDate = new Date(2016, 2, 6, 0, 0, inmemorycounter, 0);
            var h = elusionX.inmemory.pad(inmemoryStartDate.getHours());
            var m = elusionX.inmemory.pad(inmemoryStartDate.getMinutes());
            var s = elusionX.inmemory.pad(inmemoryStartDate.getSeconds());
            var current_time = [h, m, s].join(':');
            if (clock) {
                clock.innerHTML = current_time;
                elusionX.perfSummary.inmemory.totaltime = current_time;
            }
            ++inmemorycounter;
        },

        pad: function (x) {
            return x < 10 ? '0' + x : x;
        }
    },
    perfSummary: {
        disk: {
            batchrequests: [],
            latchwaits: [],
            contextswitches: [],
            totaltime: '',
            avgtimeperorder: 0,
            users: 0,
            estimatedloss: '',
            totalOrders: 0,
            totalvalue: 0,
            avgvalue: '',
            requests: [],
            sessions: [],
            cpu: []
        },
        inmemory: {
            batchrequests: [],
            contextswitches: [],
            latchwaits: [],
            pageiolatches: [],
            totaltime: '',
            avgtimeperorder: 0,
            users: 0,
            estimatedloss: '',
            totalOrders: 0,
            totalvalue: 0,
            avgvalue: '',
            requests: [],
            sessions: [],
            cpu: []
        },
        getSeconds: function (value) {
            var values = value.split(':');
            return (parseInt(values[0]) * 60 * 60) + (parseInt(values[1]) * 60) + parseInt(values[2]);
        },
        renderPerfSummary: function () {
            if (!inmemoryhubstopped) return;
            $('#scenario1title').text('');
            $('.container').block({
                message: null
            });

            $('#d-p-estimatedloss').text(elusionX.perfSummary.disk.estimatedloss);
            $('#d-p-totalorders').text(elusionX.perfSummary.disk.totalOrders);
            $('#d-p-totalvalue').text(elusionX.perfSummary.disk.totalvalue);
            $('#d-p-avgvalue').text('$ ' + elusionX.perfSummary.disk.avgvalue);

            $('#i-p-estimatedloss').text(elusionX.perfSummary.inmemory.estimatedloss);
            $('#i-p-totalorders').text(elusionX.perfSummary.inmemory.totalOrders);
            $('#i-p-totalvalue').text(elusionX.perfSummary.inmemory.totalvalue);
            $('#i-p-avgvalue').text('$ ' + elusionX.perfSummary.inmemory.avgvalue);

            //Row 2
            $('#d-p-totaltime').text(elusionX.perfSummary.disk.totaltime);
            $('#d-p-avgtime').text(elusionX.perfSummary.disk.avgtimeperorder);
            $('#d-p-users').text(elusionX.perfSummary.disk.users.format());


            
            //row-3
            var dAvgBatchRequests = 0;
            $.each(elusionX.perfSummary.disk.batchrequests, function () {
                dAvgBatchRequests = dAvgBatchRequests + this.y;
            });
            $('#d-p-avgbr').text(Math.round(dAvgBatchRequests / elusionX.perfSummary.disk.batchrequests.length));
            var iAvgBatchRequests = 0;
            $.each(elusionX.perfSummary.inmemory.batchrequests, function () {
                iAvgBatchRequests = iAvgBatchRequests + this.y;
            });
            $('#i-p-avgbr').text(Math.round(iAvgBatchRequests / elusionX.perfSummary.inmemory.batchrequests.length));

            var dAvgLatches = 0;
            $.each(elusionX.perfSummary.disk.latchwaits, function () {
                dAvgLatches = dAvgLatches + this.y;
            });
            var dlatches = Math.round(dAvgLatches / elusionX.perfSummary.disk.latchwaits.length);
            $('#d-p-avglatches').text(isNaN(dlatches) ? 0 : dlatches);

            var iAvgLatches = 0;
            $.each(elusionX.perfSummary.inmemory.latchwaits, function () {
                iAvgLatches = iAvgLatches + this.y;
            });
            var ilatches = Math.round(iAvgLatches / elusionX.perfSummary.inmemory.latchwaits.length);
            $('#i-p-avglatches').text(isNaN(ilatches) ? 0 : ilatches);


            var dAvgBatchCPU = 0;
            $.each(elusionX.perfSummary.disk.cpu, function () {
                dAvgBatchCPU = dAvgBatchCPU + this.y;
            });
            $('#d-p-avgcpu').text(Math.round(dAvgBatchCPU / elusionX.perfSummary.disk.cpu.length));

            var iAvgBatchCPU = 0;
            $.each(elusionX.perfSummary.inmemory.cpu, function () {
                iAvgBatchCPU = iAvgBatchCPU + this.y;
            });
            $('#i-p-avgcpu').text(Math.round(iAvgBatchCPU / elusionX.perfSummary.inmemory.cpu.length));

            var dContextSwitches = 0;
            $.each(elusionX.perfSummary.disk.contextswitches, function () {
                dContextSwitches = dContextSwitches + this.y;
            });
            $('#d-p-avgcontextswitches').text(Math.round(dContextSwitches / elusionX.perfSummary.disk.contextswitches.length));
            var iContextSwitches = 0;
            $.each(elusionX.perfSummary.inmemory.contextswitches, function () {
                iContextSwitches = iContextSwitches + this.y;
            });
            $('#i-p-avgcontextswitches').text(Math.round(iContextSwitches / elusionX.perfSummary.inmemory.contextswitches.length));

            $('#i-p-totaltime').text(elusionX.perfSummary.inmemory.totaltime);
            $('#i-p-timeperorder').text(elusionX.perfSummary.inmemory.avgtimeperorder);
            $('#i-p-users').text(elusionX.perfSummary.inmemory.users.format());

            var diskbasedtotaltime = elusionX.perfSummary.getSeconds(elusionX.perfSummary.disk.totaltime);
            var inmemorytotaltime = elusionX.perfSummary.getSeconds(elusionX.perfSummary.inmemory.totaltime);
            var improvement = Math.round(diskbasedtotaltime / inmemorytotaltime);
            $('#perfsummary-impr').text(improvement + 'X');
            setInterval(function () {
                $('#perimpr-panel').fadeOut(500);
                $('#perimpr-panel').fadeIn(500);
            }, 1000);
            //In order to make the CPU graph consists check if cpu points are same in 
            // disk based and inmemory or else add dummy to inmemory
            var d = elusionX.perfSummary.disk.cpu.length;
            var i = elusionX.perfSummary.inmemory.cpu.length;
            var last = elusionX.perfSummary.inmemory.cpu.pop();
            for (var k = 0; k < (diskbasedtotaltime - inmemorytotaltime) * 2  ; k++) {
                elusionX.perfSummary.inmemory.cpu.push({ x: (new Date(last.x)).setSeconds(new Date(last.x).getSeconds() + (k + 0.25)), y: 0 })
            }
            //Row 4
            var dptmetrics2 = {
                chart: {
                    renderTo: 'd-p-tmetrics2'
                },
                xAxis: {
                    type: 'datetime',
                    tickPixelInterval: 150,
                    title: { text: 'Time' }
                },
                yAxis: {
                    min: 0,
                    max: 100
                },
                series: [{
                    name: '%CPU Usage',
                    data: elusionX.perfSummary.disk.cpu,
                    color: diskbasedColor
                }
                ]
            };
            var cpuchart1 = new Highcharts.Chart(jQuery.extend(true, {}, defaultAreaChart, dptmetrics2));
            var iptmetrics2 = {
                chart: {
                    renderTo: 'i-p-tmetrics2'
                },
                xAxis: {
                    type: 'datetime',
                    tickPixelInterval: 150,
                    title: { text: 'Time' }
                },
                yAxis: {
                    min: 0,
                    max: 100
                },
                series: [{
                    name: '%CPU Usage',
                    data: elusionX.perfSummary.inmemory.cpu,
                    color: inmemoryColor
                }
                ]
            };
            var cpuchart2 = new Highcharts.Chart(jQuery.extend(true, {}, defaultAreaChart, iptmetrics2));
            cpuchart1.series[0].setData(elusionX.perfSummary.disk.cpu);
            cpuchart2.series[0].setData(elusionX.perfSummary.inmemory.cpu);
            $('#inmemory-businesstab').removeClass('active in');
            $('#inmemory-business').removeClass('active in');
            $('#inmemory-technical').removeClass('active in');
            $('#inmemory-technicaltab').removeClass('active in');
            $('#performancesummarytab').removeAttr('style');
            $('#performancesummary').removeAttr('style');
            $('#performancesummarytab').addClass('active in');
            $('#performancesummary').addClass('active in');
            $('.container').unblock();
            $('div#performancesummary span').each(function (index, element) {
                $(this).css('font-size', '30px');
            });
        }
    }
}
elusionX.diskBased.init();
