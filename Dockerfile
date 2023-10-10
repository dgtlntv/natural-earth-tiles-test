# Use Ubuntu as the base image
FROM ubuntu:latest

# Set environment variables to non-interactive (this will prevent some prompts)
ENV DEBIAN_FRONTEND=non-interactive

# Install required dependencies and utilities
RUN apt-get update && \
    apt-get install -y \
    curl \
    unzip \
    git \
    build-essential \
    libsqlite3-dev \
    zlib1g-dev \
    gdal-bin && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install Tippecanoe
RUN git clone https://github.com/mapbox/tippecanoe.git && \
    cd tippecanoe && \
    make -j && \
    make install

# Set the working directory
WORKDIR /data

# Execute provided commands to get and process data
RUN curl -L -O https://www.naturalearthdata.com/http//www.naturalearthdata.com/download/10m/cultural/ne_10m_admin_0_countries.zip && \
    unzip ne_10m_admin_0_countries.zip && \
    ogr2ogr -f GeoJSON ne_10m_admin_0_countries.geojson ne_10m_admin_0_countries.shp && \
    \
    curl -L -O https://www.naturalearthdata.com/http//www.naturalearthdata.com/download/10m/cultural/ne_10m_admin_1_states_provinces.zip && \
    unzip -o ne_10m_admin_1_states_provinces.zip && \
    ogr2ogr -f GeoJSON ne_10m_admin_1_states_provinces.geojson ne_10m_admin_1_states_provinces.shp && \
    \
    curl -L -O https://www.naturalearthdata.com/http//www.naturalearthdata.com/download/10m/physical/ne_10m_ocean.zip && \
    unzip -o ne_10m_ocean.zip && \
    ogr2ogr -f GeoJSON ne_10m_ocean.geojson ne_10m_ocean.shp && \
    \
    curl -L -O https://www.naturalearthdata.com/http//www.naturalearthdata.com/download/10m/physical/ne_10m_land.zip && \
    unzip -o ne_10m_land.zip && \
    ogr2ogr -f GeoJSON ne_10m_land.geojson ne_10m_land.shp && \
    \
    curl -L -O https://www.naturalearthdata.com/http//www.naturalearthdata.com/download/10m/physical/ne_10m_rivers_lake_centerlines_scale_rank.zip && \
    unzip -o ne_10m_rivers_lake_centerlines_scale_rank.zip  && \
    ogr2ogr -f GeoJSON ne_10m_rivers_lake_centerlines_scale_rank.geojson ne_10m_rivers_lake_centerlines_scale_rank.shp && \
    \
    curl -L -O https://www.naturalearthdata.com/http//www.naturalearthdata.com/download/10m/physical/ne_10m_lakes.zip && \
    unzip -o ne_10m_lakes.zip && \
    ogr2ogr -f GeoJSON ne_10m_lakes.geojson ne_10m_lakes.shp && \
    \
    # This one bugs out for some reason
    #curl -L -O https://www.naturalearthdata.com/http//www.naturalearthdata.com/download/10m/physical/ne_10m_geography_regions_polys.zip && \
    #unzip -o ne_10m_geography_regions_polys.zip && \
    #ogr2ogr -f ne_10m_geography_regions_polys.geojson ne_10m_geography_regions_polys.shp && \
    #\
    curl -L -O https://www.naturalearthdata.com/http//www.naturalearthdata.com/download/10m/cultural/ne_10m_admin_0_disputed_areas.zip && \
    unzip -o ne_10m_admin_0_disputed_areas.zip  && \
    ogr2ogr -f GeoJSON ne_10m_admin_0_disputed_areas.geojson ne_10m_admin_0_disputed_areas.shp && \
    \
    curl -L -O https://www.naturalearthdata.com/http//www.naturalearthdata.com/download/10m/cultural/ne_10m_populated_places.zip && \
    unzip -o ne_10m_populated_places.zip && \
    ogr2ogr -f GeoJSON ne_10m_populated_places.geojson ne_10m_populated_places.shp && \
    \
    curl -L -O https://www.naturalearthdata.com/http//www.naturalearthdata.com/download/10m/cultural/ne_10m_roads.zip && \
    unzip -o ne_10m_roads.zip && \
    ogr2ogr -f GeoJSON ne_10m_roads.geojson ne_10m_roads.shp && \
    \
    curl -L -O https://www.naturalearthdata.com/http//www.naturalearthdata.com/download/10m/cultural/ne_10m_time_zones.zip && \
    unzip -o ne_10m_time_zones.zip && \
    ogr2ogr -f GeoJSON ne_10m_time_zones.geojson ne_10m_time_zones.shp && \
    \
    tippecanoe -z3 -o countries-z3.mbtiles --coalesce-densest-as-needed ne_10m_admin_0_countries.geojson && \
    tippecanoe -zg -Z4 -o states-Z4.mbtiles --coalesce-densest-as-needed --extend-zooms-if-still-dropping ne_10m_admin_1_states_provinces.geojson && \
    tippecanoe -zg -o ocean.mbtiles --coalesce-densest-as-needed --extend-zooms-if-still-dropping ne_10m_ocean.geojson && \
    tippecanoe -zg -o land.mbtiles --coalesce-densest-as-needed --extend-zooms-if-still-dropping ne_10m_land.geojson && \
    tippecanoe -zg -Z4 -o rivers-Z4.mbtiles --coalesce-densest-as-needed --extend-zooms-if-still-dropping ne_10m_rivers_lake_centerlines_scale_rank.geojson && \
    tippecanoe -zg -Z4 -o lakes-Z4.mbtiles --coalesce-densest-as-needed --extend-zooms-if-still-dropping ne_10m_lakes.geojson && \
    #tippecanoe -zg -Z4 -o regions-Z4.mbtiles --coalesce-densest-as-needed --extend-zooms-if-still-dropping ne_10m_geography_regions_polys.geojson && \
    tippecanoe -zg -Z4 -o disputed-Z4.mbtiles --coalesce-densest-as-needed --extend-zooms-if-still-dropping ne_10m_admin_0_disputed_areas.geojson && \
    tippecanoe -zg -Z4 -o populated-Z4.mbtiles --coalesce-densest-as-needed --extend-zooms-if-still-dropping ne_10m_populated_places.geojson && \
    tippecanoe -zg -Z6 -o roads-Z6.mbtiles --coalesce-densest-as-needed --extend-zooms-if-still-dropping ne_10m_roads.geojson && \
    tippecanoe -z2 -o countries-z2.mbtiles --coalesce-densest-as-needed ne_10m_time_zones.geojson && \
    tile-join -o merger.mbtiles countries-z3.mbtiles states-Z4.mbtiles ocean.mbtiles land.mbtiles rivers-Z4.mbtiles lakes-Z4.mbtiles disputed-Z4.mbtiles populated-Z4.mbtiles roads-Z6.mbtiles countries-z2.mbtiles