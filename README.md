A package for creating simple yet modern looking charts.

#### Five chart types
- Bar
![](https://raw.githubusercontent.com/jolleekin/modern_charts/master/doc/images/bar.png)

- Gauge
![](https://raw.githubusercontent.com/jolleekin/modern_charts/master/doc/images/gauge.png)

- Line
![](https://raw.githubusercontent.com/jolleekin/modern_charts/master/doc/images/line.png)

- Pie/Donut
![](https://raw.githubusercontent.com/jolleekin/modern_charts/master/doc/images/pie.png)

- Radar
![](https://raw.githubusercontent.com/jolleekin/modern_charts/master/doc/images/radar.png)

#### Canvas + DOM
**modern_charts** combines Canvas and DOM to achieve the best performance and
experience.
- Canvas is used to render chart contents (axes, grids, and series)
- DOM is used to create legends and tooltips

#### DataTable
Data are passed to a chart via a `DataTable` object. By using `DataTable`, you
can flexibly modify the data even after the chart has been rendered. 

#### Animations
Animations are supported for different types of data modifications:
- New data table
- Changes to data table values
- Insertion and removal of rows (categories)
- Insertion and removal of columns (series)
- Series visibility toggle

#### Responsive
Charts automatically resize when the browser is resized.

#### Interactive
- Shows tooltips on hover/tap
- The visibility of a series is toggled when you click the corresponding legend
  item

#### Modular
Each chart type has its own class, so your final production code only contains
the code of the chart types you use.

#### Usage
Please read the wiki for instructions on how to use these beautiful charts.