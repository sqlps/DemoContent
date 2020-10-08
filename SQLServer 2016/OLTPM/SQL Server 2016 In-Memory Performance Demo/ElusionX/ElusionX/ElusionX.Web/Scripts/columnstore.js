var csChart, nciChart, ciStartDate, csStartDate, clearCIInterval, clearCSInterval, counter = 0, columnstorecounter = 0;
var showImprovementFlashInterval;
var columnstore = {
    init: function () {
        $('#p-csperf').hide();
        $('#diskbasedsubmitquery').hide();
        $('#perfsummary').hide();
        $('#getcireport').show();
        $('#getcireport').on('click', columnstore.getmetricswithoutcolumnstore);
        columnstore.showRowCount();
    },

    ciTickTock: function () {
        var clock = document.querySelector('digiclockci');
        ciStartDate = new Date(2016, 2, 6, 0, 0, counter, 999);
        var h = columnstore.pad(ciStartDate.getHours());
        var m = columnstore.pad(ciStartDate.getMinutes());
        var s = columnstore.pad(ciStartDate.getSeconds());
        var current_time = [h, m, s].join(':');
        if (clock) {
            clock.innerHTML = current_time;
        }
        ++counter;
    },

    csTickTock: function () {
        var clock = document.querySelector('digiclockcs');
        csStartDate = new Date(2016, 2, 6, 0, 0, columnstorecounter, 999);
        var h = columnstore.pad(csStartDate.getHours());
        var m = columnstore.pad(csStartDate.getMinutes());
        var s = columnstore.pad(csStartDate.getSeconds());
        var current_time = [h, m, s].join(':');
        if (clock) {
            clock.innerHTML = current_time;
        }
        ++columnstorecounter;
    },

    pad: function (x) {
        return x < 10 ? '0' + x : x;
    },

    getmetricswithoutcolumnstore: function () {
        counter = 0;
        columnstorecounter = 0;
        clearInterval(clearCIInterval);
        clearInterval(clearCSInterval);
        clearInterval(showImprovementFlashInterval);
        $('#p-csperf').hide();
        columnstore.ciTickTock();
        $.ajax({
            url: "/Home/getmetricswithoutcolumnstore",
            dataType: "json",
            cache: false,
            contentType: 'application/json; charset=utf-8',
            type: "GET",
            success: function (data) {
                clearInterval(clearCIInterval);
                var result = data.result;
                var colors = Highcharts.getOptions().colors;
                var result = data.result;
                var categories = [], data = [];
                $.each(result, function (i, r) {
                    categories.push(this.year);
                    data.push(
                        {
                            y: this.values,
                            color: diskbasedColor,
                            drilldown: this.year
                        });
                });
                $('#cireport').unblock();
                columnstore.drawBarGraph('cireport', data, categories, columnstore.redrawforwithoutcolumnstore)
                columnstore.showperimprovement();
            },
            error: function () { }
        });
        clearCIInterval = setInterval(columnstore.ciTickTock, 1000);
        $('#cireport').block({
            message: "<img src='/images/loading.gif' style='height:50px;width:50px'></img>"
        });
        $(".blockMsg").css("background-color", "#3d3d3d");
        $(".blockMsg").css("border", "0px");
        columnstore.getmetricswithcolumnstore();
    },

    showperimprovement: function () {
        var ciseconds = columnstore.getSeconds(document.querySelector('digiclockci').innerHTML);
        var csseconds = columnstore.getSeconds(document.querySelector('digiclockcs').innerHTML);
        if (csseconds == 0)
            ++csseconds;
        $('#columnstore-impr').text(' ' + Math.round(ciseconds / csseconds) + 'X ');
        showImprovementFlashInterval = setInterval(function () {
            $('#p-csperf').fadeOut(500);
            $('#p-csperf').fadeIn(500);
        }, 1000);
        $('#p-csperf').show();
    },

    getmetricswithcolumnstore: function () {
        columnstore.csTickTock();
        $.ajax({
            url: "/Home/getmetricswithcolumnstore",
            dataType: "json",
            contentType: 'application/json; charset=utf-8',
            type: "GET",
            cache: false,
            success: function (data) {
                clearInterval(clearCSInterval);
                var colors = Highcharts.getOptions().colors;
                var result = data.result;
                var categories = [], data = [];
                $.each(result, function (i, r) {
                    categories.push(this.year);
                    data.push(
                        {
                            y: this.values,
                            color: '#ec971f',
                            drilldown: this.year
                        });
                });
                $('#csreport').unblock();
                columnstore.drawBarGraph('csreport', data, categories, columnstore.redrawforcolumnstore)
            },
            error: function () { }
        });
        clearCSInterval = setInterval(columnstore.csTickTock, 1000);
        $('#csreport').block({
            message: "<img src='/images/loading.gif' style='height:50px;width:50px'></img>"
        });
        $(".blockMsg").css("background-color", "#3d3d3d");
        $(".blockMsg").css("border", "0px");
    },

    drawBarGraph: function (renderToDiv, data, categoriesData, onClickFunction) {
        var chartOptions = {
            chart: {
                renderTo: renderToDiv
            },
            xAxis: {
                categories: categoriesData,
                labels: { style: { fontSize: '15px' } }
            },
            yAxis: {
                labels: { style: { fontSize: '15px' } }
            },
            title: {
                text: 'Year Wise Product Sales'
            },
            legend: {
                color: renderToDiv == 'csreport' ? diskbasedColor : inmemoryColor
            },
            tooltip: {
                headerFormat: '<span style="font-size:11px">{series.name}</span><br>',
                pointFormat: '<span style="color:{point.color}">{point.drilldown}</span>: <b>{point.y:.2f}</b><br/>Click on the bar to drill down further.'
            },
            plotOptions: {
                column: {
                    point: {
                        events: {
                            click: function (drilldown) {
                                clearInterval(showImprovementFlashInterval);
                                $('#p-csperf').hide();
                                var category = this.category;
                                var color = this.color;
                                onClickFunction(category);
                            }
                        }
                    }
                }
            },
            series: [{
                name: 'Year',
                data: data,
                color: renderToDiv == 'cireport' ? diskbasedColor : inmemoryColor
            }]
        }
        var chart = new Highcharts.Chart(jQuery.extend(true, {}, defaultBarChart, chartOptions));
    },

    getMonthFromString: function (mon) {
        var months = ["jan", "feb", "mar", "apr", "may", "jun", "jul", "aug", "sep", "oct", "nov", "dec"];
        return months[parseInt(mon) - 1];
    },

    redrawforcolumnstore: function (category) {
        $('#csreport').block({
            message: "<img src='/images/loading.gif' style='height:50px;width:50px'></img>"
        });
        columnstorecounter = 0;
        columnstore.csTickTock();
        clearCSInterval = setInterval(columnstore.csTickTock, 1000);
        $.ajax({
            url: "/Home/getmetricswithcolumnstore?year=" + category,
            dataType: "json",
            contentType: 'application/json; charset=utf-8',
            type: "GET",
            cache: false,
            success: function (data) {
                var result = data.result;
                var categories = [], data = [];
                $.each(result, function (i, r) {
                    categories.push(columnstore.getMonthFromString(this.year));
                    data.push({
                        y: this.values,
                        color: inmemoryColor,
                        drilldown: this.year
                    })
                });
                var chartOptions = {
                    chart: {
                        renderTo: 'csreport'
                    },
                    title: {
                        text: 'Product Sales for Year: ' + category
                    },
                    xAxis: {
                        categories: categories,
                    },
                    series: [{
                        name: 'Months',
                        data: data,
                        color: inmemoryColor
                    }]
                }
                var chart = new Highcharts.Chart(jQuery.extend(true, {}, defaultBarChart, chartOptions));
                $('#csreport').unblock();
                clearInterval(clearCSInterval);
            },
            error: function () { }
        });
    },

    redrawforwithoutcolumnstore: function (category) {
        $('#cireport').block({
            message: "<img src='/images/loading.gif' style='height:50px;width:50px'></img>"
        });
        counter = 0;
        columnstore.ciTickTock();
        clearCIInterval = setInterval(columnstore.ciTickTock, 1000);
        $.ajax({
            url: "/Home/getmetricswithoutcolumnstore?year=" + category,
            dataType: "json",
            contentType: 'application/json; charset=utf-8',
            type: "GET",
            cache: false,
            success: function (data) {
                var result = data.result;
                var categories = [], data = [];
                $.each(result, function (i, r) {
                    categories.push(columnstore.getMonthFromString(this.year));
                    data.push({
                        y: this.values,
                        color: diskbasedColor,
                        drilldown: this.year
                    })
                });
                var chartOptions = {
                    chart: {
                        renderTo: 'cireport'
                    },
                    title: {
                        text: 'Product Sales for Year: ' + category
                    },
                    xAxis: {
                        categories: categories,
                    },
                    series: [{
                        name: 'Months',
                        data: data,
                        color: diskbasedColor
                    }]
                }
                var chart = new Highcharts.Chart(jQuery.extend(true, {}, defaultBarChart, chartOptions));
                $('#cireport').unblock();
                clearInterval(clearCIInterval);
                columnstore.showperimprovement();
            },
            error: function () { }
        });
    },

    showRowCount: function () {
        $.ajax({
            url: "/Home/getrowcounts",
            dataType: "json",
            cache: false,
            contentType: 'application/json; charset=utf-8',
            type: "GET",
            success: function (data) {
                $('#csrowscount').text(data.csrowcount.format());
                $('#cirowscount').text(data.cirowcount.format());
            },
            error: function () { }
        });
    },

    getSeconds: function (value) {
        var values = value.split(':');
        return (parseInt(values[0]) * 60 * 60) + (parseInt(values[1]) * 60) + parseInt(values[2]);
    }
};

columnstore.init();