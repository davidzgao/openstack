$cross.ngGridFlexibleHeightPlugin = function (opts) {
    var self = this;
    self.grid = null;
    self.scope = null;
    self.init = function (scope, grid, services) {
        self.domUtilityService = services.DomUtilityService;
        self.grid = grid;
        self.scope = scope;
        var recalcHeightForData = function () { setTimeout(innerRecalcForData, 1); };
        var innerRecalcForData = function () {
            var gridId = self.grid.gridId;
            var footerPanelSel = '.' + gridId + ' .ngFooterPanel';
            var extraHeight = self.grid.$topPanel.height() + $(footerPanelSel).height();
            var naturalHeight = self.grid.$canvas.height() + 1;
            if (opts != null) {
                if (opts.minHeight != null && (naturalHeight + extraHeight) < opts.minHeight) {
                    naturalHeight = opts.minHeight - extraHeight - 2;
                }
            }

            var newViewportHeight = naturalHeight + 5;
            if (!self.scope.baseViewportHeight || self.scope.baseViewportHeight !== newViewportHeight) {
                self.grid.$viewport.css('height', newViewportHeight + 'px');
                self.grid.$root.css('height', (newViewportHeight + extraHeight) + 'px');
                self.scope.baseViewportHeight = newViewportHeight;
                self.domUtilityService.RebuildGrid(self.scope, self.grid);
            }
        };
        self.scope.catHashKeys = function () {
            var hash = '',
                idx;
            for (idx in self.scope.renderedRows) {
                hash += self.scope.renderedRows[idx].$$hashKey;
            }
            return hash;
        };
        self.scope.$watch('catHashKeys()', innerRecalcForData);
        self.scope.$watch(self.grid.config.data, recalcHeightForData);
    };
};

$cross.resizeViewPort = function () { // and the two steps below
  // retrieve viewPortHeight
  var viewportHeight = $('ngViewPort').height();
  var gridHeight = $('ngGrid').height();

  // set the .ngGridStyle or the first parent of my ngViewPort in current scope
  var viewportHeight = $('.ngViewport').height();
  var canvasHeight = $('.ngCanvas').height();
  var gridHeight = $('.ngGrid').height();

  var finalHeight = canvasHeight;
  var minHeight = 150;
  var maxHeight = 300;


  // if the grid height less than 150 set to 150, same for > 300 set to 300
  if (finalHeight < minHeight) {
    finalHeight = minHeight;
  } else if (finalHeight > viewportHeight) {
    finalHeight = maxHeight;
  }

  $(".ngViewport").height(finalHeight);
}
