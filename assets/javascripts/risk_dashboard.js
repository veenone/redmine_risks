// Dashboard charts and functionality

function initDashboardCharts(
    statusLabels, statusData,
    strategyLabels, strategyData,
    probabilityLabels, probabilityData,
    impactLabels, impactData
  ) {
    // Colors for charts
    var chartColors = {
      blue: 'rgba(54, 162, 235, 0.8)',
      blueLight: 'rgba(54, 162, 235, 0.2)',
      green: 'rgba(75, 192, 192, 0.8)',
      greenLight: 'rgba(75, 192, 192, 0.2)',
      red: 'rgba(255, 99, 132, 0.8)',
      redLight: 'rgba(255, 99, 132, 0.2)',
      orange: 'rgba(255, 159, 64, 0.8)',
      orangeLight: 'rgba(255, 159, 64, 0.2)',
      purple: 'rgba(153, 102, 255, 0.8)',
      purpleLight: 'rgba(153, 102, 255, 0.2)',
      yellow: 'rgba(255, 205, 86, 0.8)',
      yellowLight: 'rgba(255, 205, 86, 0.2)',
      grey: 'rgba(201, 203, 207, 0.8)',
      greyLight: 'rgba(201, 203, 207, 0.2)'
    };
    
    var statusColors = [
      chartColors.blue,
      chartColors.green,
      chartColors.red
    ];
    
    var strategyColors = [
      chartColors.green,
      chartColors.blue,
      chartColors.orange,
      chartColors.purple
    ];
    
    // Create Status chart
    if (document.getElementById('risksStatusChart')) {
      var statusCtx = document.getElementById('risksStatusChart').getContext('2d');
      var statusChart = new Chart(statusCtx, {
        type: 'doughnut',
        data: {
          labels: statusLabels,
          datasets: [{
            data: statusData,
            backgroundColor: statusColors,
            borderWidth: 0
          }]
        },
        options: {
          responsive: true,
          maintainAspectRatio: false,
          legend: {
            position: 'right',
            labels: {
              boxWidth: 12
            }
          }
        }
      });
    }
    
    // Create Strategy chart
    if (document.getElementById('risksStrategyChart')) {
      var strategyCtx = document.getElementById('risksStrategyChart').getContext('2d');
      var strategyChart = new Chart(strategyCtx, {
        type: 'doughnut',
        data: {
          labels: strategyLabels,
          datasets: [{
            data: strategyData,
            backgroundColor: strategyColors,
            borderWidth: 0
          }]
        },
        options: {
          responsive: true,
          maintainAspectRatio: false,
          legend: {
            position: 'right',
            labels: {
              boxWidth: 12
            }
          }
        }
      });
    }
    
    // Create Distribution chart
    if (document.getElementById('riskDistributionChart')) {
      var distributionCtx = document.getElementById('riskDistributionChart').getContext('2d');
      var distributionChart = new Chart(distributionCtx, {
        type: 'bar',
        data: {
          labels: probabilityLabels,
          datasets: [
            {
              label: 'Probability',
              data: probabilityData,
              backgroundColor: chartColors.blue,
              borderColor: chartColors.blue,
              borderWidth: 1
            },
            {
              label: 'Impact',
              data: impactData,
              backgroundColor: chartColors.red,
              borderColor: chartColors.red,
              borderWidth: 1
            }
          ]
        },
        options: {
          responsive: true,
          maintainAspectRatio: false,
          scales: {
            yAxes: [{
              ticks: {
                beginAtZero: true
              }
            }]
          }
        }
      });
    }
  }
  
  // Handle tab switching in the dashboard if needed
  $(document).ready(function() {
    // Toggle visibility of dashboard cards when needed
    $('.dashboard-toggle').on('click', function(e) {
      e.preventDefault();
      var target = $(this).data('target');
      $('#' + target).slideToggle();
      $(this).toggleClass('collapsed');
    });
    
    // Handle any other dashboard interactions
    $('.risk-filter-link').on('click', function(e) {
      // Custom filter handling if needed
    });
  });