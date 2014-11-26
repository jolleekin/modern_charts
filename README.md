A package for creating simple yet modern looking charts.

#### Four chart types
- Bar
- Line
- Pie/Donut
- Radar

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
- Support for tooltips and legends
- When you click a legend item, the visibility of the corresponding series is
  toggled.

#### Modular
Each chart type has its own class, so your final production code only contains
the code of the chart types you use.