#### 0.1.12
- LineChart: fix a bug causing data labels not to be displayed even when enabled

#### 0.1.11
- LineChart: add `series:markers:enabled` option
- RadarChart: add `series:markers:enabled` option

#### 0.1.10
- All: change the default background color of legend to transparent
- BarChart: change bar group hover effect
- BarChart: change tooltip offset
- BarChart: change the positions of x-axis tick marks based on whether x-axis labels are skipped or not
- BarChart, LineChart: hide x-axis tick marks whose corresponding labels are hidden
- BarChart, LineChart: axis label baselines are adjusted with respect to font size
- BarChart, LineChart: fix a bug in the calculation of hovered entity group

#### 0.1.9
- GaugeChart: fix a bug that causes the tooltip not to show when hovering the top left quadrant 
- LineChart: adjust the position of x-axis labels so they span the whole x-axis

#### 0.1.8
- BarChart: add `xAxis:labels:maxRotation` and `xAxis:labels:minRotation`
- LineChart: add `xAxis:labels:maxRotation` and `xAxis:labels:minRotation`

#### 0.1.7
- Fix tooltip label formatter and value formatter
- Update README.md

#### 0.1.6
- Fix [#10](https://github.com/jolleekin/modern_charts/issues/10)
- Fix broken links in __CHANGELOG.md__
- Enable strong mode
- Perform code cleanup
- Improve performance
- `animation:easing` now accepts a function
- Add `DataRow.toList`
- Rename `degree` to `rad2deg` and `radian` to `deg2rad` in `utils.dart`
- PieChart: Add `series:counterclockwise` and `series:startAngle` options
- PieChart: Pie labels, if enabled, are now displayed during animations
- PieChart: Fix tooltip position when `pieHole` > 0

#### 0.1.5
- Change the semantics of `yAxis:minValue` and `yAxis:maxValue`
- Add `tooltip:labelFormatter` and `legend:labelFormatter`

#### 0.1.4
- Add a 500ms delay before resizing all charts
- Correct gauge center and outer radius

#### 0.1.3
- Fix [#7](https://github.com/jolleekin/modern_charts/issues/7)
- Fix [#8](https://github.com/jolleekin/modern_charts/issues/8)
- Add `yAxis`:`minInterval` setting to BarChart, LineChart, and RadarChart
- Perform code cleanup

#### 0.1.2
- Fix [#5](https://github.com/jolleekin/modern_charts/issues/5)
- Fix [#6](https://github.com/jolleekin/modern_charts/issues/6)
- Format code using `dartfmt`

#### 0.1.1
- Fixed the legend-position-none bug

#### 0.1.0
-	Initial version