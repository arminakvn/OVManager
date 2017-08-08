## using SMDataManager Module for removing multiple polygon areas from OSM files
### desctiption and example

This module is created for altering Open Street Map's data, in order to remove multiple areas (chuncks) using .poly files.
Specifications regarding the `poly` format could be found [here](http://wiki.openstreetmap.org/wiki/Osmosis/Polygon_Filter_File_Format). Example and tutorial for creating `poly` files in QGIS are available [here](https://mvexel.blog/2011/11/05/tutorial-poly/).

The _manager_ instance is initialized with two arguements: path to the folser containing the `poly` file(s) and open street map data, for example `m` is initiated in example below :


with two input variables where `/home/ubuntu/scripts/polyrema/` is the location where the `.poly` files are located, with a base OSM file downloaded from `geofabrik`'s data extracts webpage.


```{ruby}
m = OSMDataManager::OSMDataEvent.new('/home/ubuntu/scripts/polyrema/','/home/ubuntu/data/us-northeast-latest.osm.pbf')

```
Additionaly, it's a good idea to first clip the base OSM file to a smaller extent. This could be done by passing the location of another `.poly` file, so


```{ruby}
m.clipExtent("/home/ubuntu/scripts/bound/mapoly.poly")
```

will clip the northeast to a smaller area of only a state (here MA).

Running the following will start a chain of processes for extracting each polygon, creating a intermidiete polygon and repeating this for the next polygon:

```{r}
m.go
```


