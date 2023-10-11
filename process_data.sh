#!/bin/bash

# Parse config file
CONFIG_FILE="$1"
BASE_URL=$(yq e '.base_url' "$CONFIG_FILE")

# Declare an array to store all the generated pmtiles filenames
declare -a PMTILES_FILES

# Download, extract, transform, and generate tiles
for layer in $(yq e '.layers[].name' "$CONFIG_FILE"); do
  TYPE=$(yq e '.layers[] | select(.name == "'"$layer"'") | .type' "$CONFIG_FILE")
  START_ZOOM=$(yq e '.layers[] | select(.name == "'"$layer"'") | .start_zoom' "$CONFIG_FILE")
  END_ZOOM=$(yq e '.layers[] | select(.name == "'"$layer"'") | .end_zoom' "$CONFIG_FILE")
  URL="$BASE_URL$TYPE/$layer.zip"
  
  if ! curl --retry 5 --retry-delay 10 -L -O "$URL"; then
    echo "Failed to download $URL"
    continue
  fi
  
  if ! unzip -o "$layer.zip"; then
    echo "Failed to unzip $layer.zip"
    continue
  fi
  
  if ! ogr2ogr -f GeoJSON "$layer.geojson" "$layer.shp"; then
    echo "Failed to transform $layer.shp to $layer.geojson"
    continue
  fi
  
  output_pmtiles="$layer-Z$END_ZOOM.pmtiles"
  if ! tippecanoe -z"$END_ZOOM" -Z"$START_ZOOM" -o "$output_pmtiles" --coalesce-densest-as-needed "$layer.geojson"; then
    echo "Failed to generate tiles for $layer.geojson"
    continue
  fi
  
  # Append the generated pmtiles filename to the array
  PMTILES_FILES+=("$output_pmtiles")
done

echo "pmtiles files to join: ${PMTILES_FILES[@]}"

# Join tiles using the array of pmtiles filenames
if ! tile-join --no-tile-size-limit -overzoom -f -o world.pmtiles "${PMTILES_FILES[@]}"; then
    echo "Failed to join tiles"
    exit 1
fi

# Export the final mbtile
cp world.pmtiles /output_directory
