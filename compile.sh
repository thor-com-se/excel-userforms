#!/bin/bash

# Create the output directory if it doesn't exist
mkdir -p userforms

# Function to handle file path processing
process_path() {
    local path=$1
    local normalized_path=$2
    local output_file=$3

    # Check if the path ends with a '/' and treat it as a wildcard
    if [[ "$path" == */ ]]; then
        echo "            Handling directory path (treated as wildcard): $normalized_path"

        # Expand and concatenate all .txt files in the directory
        for txt_file in "$normalized_path"*.txt; do
            if [[ -f "$txt_file" ]]; then
                echo "                Found .txt file: $txt_file"

                # Insert filename with '=' padding line before the file content
                header_text="' ${txt_file} "
                padding=$(printf "%0.s=" {1..100})
                header_line="${header_text}${padding:${#header_text}}"
                echo "$header_line" >> "$output_file"
                echo "" >> "$output_file"  # Newline after header

                # Concatenate file contents
                cat "$txt_file" >> "$output_file"
                echo "" >> "$output_file"  # Add a newline after each file content
                echo "" >> "$output_file"  # Add an additional newline for separation
            else
                echo "                No .txt files found in $normalized_path"
            fi
        done
    else
        # Handle exact file path
        if [[ -d "$normalized_path" ]]; then
            for txt_file in "$normalized_path"/*.txt; do
                if [[ -f "$txt_file" ]]; then
                    echo "                Found .txt file: $txt_file"

                    header_text="' ${txt_file} "
                    padding=$(printf "%0.s=" {1..100})
                    header_line="${header_text}${padding:${#header_text}}"
                    echo "$header_line" >> "$output_file"
                    echo "" >> "$output_file"  # Newline after header

                    cat "$txt_file" >> "$output_file"
                    echo "" >> "$output_file"  # Newline after content
                    echo "" >> "$output_file"  # Add an additional newline for separation
                else
                    echo "                No .txt files found in $normalized_path"
                fi
            done
        else
            if [[ ! "$normalized_path" == *.txt ]]; then
                normalized_path="${normalized_path}.txt"
            fi

            if [[ -f "$normalized_path" ]]; then
                echo "            Found exact .txt file: $normalized_path"

                header_text="' ${normalized_path} "
                padding=$(printf "%0.s=" {1..100})
                header_line="${header_text}${padding:${#header_text}}"
                echo "$header_line" >> "$output_file"
                echo "" >> "$output_file"  # Newline after header

                cat "$normalized_path" >> "$output_file"
                echo "" >> "$output_file"  # Newline after content
                echo "" >> "$output_file"  # Add an additional newline for separation
            else
                echo "            Exact .txt file not found: $normalized_path"
            fi
        fi
    fi
}

# Loop over all folders in the "resources" directory
echo "Processing folders in 'resources' directory..."

for folder in resources/userforms/*; do
    # Check if the folder contains a .json file
    for json_file in "$folder"/*.json; do
        if [[ -f "$json_file" ]]; then
            # Get the base name of the json file (without extension)
            base_name=$(basename "$json_file" .json)
            output_file="userforms/$base_name.txt"

            echo "    Processing JSON file: $json_file"
            echo "        Creating output file: $output_file"

            # Initialize an empty output file
            > "$output_file"

            # Read the JSON file and extract file paths
            file_paths=$(jq -r '.[]' "$json_file")

            # Loop over each file path in the JSON array
            for path in $file_paths; do
                # Handle paths with '../../' (step two levels up)
                if [[ "$path" == ../../* ]]; then
                    normalized_path="resources/${path#../../}"
                # Handle paths with '../' (step one level up)
                elif [[ "$path" == ../* ]]; then
                    normalized_path="resources/${path#../}"
                else
                    normalized_path="$folder/$path"
                fi

                echo "        Processing path: $path (normalized to $normalized_path)"
                
                # Handle paths ending with '/' as wildcards
                process_path "$path" "$normalized_path" "$output_file"
            done

            echo "    Finished processing $json_file"
        else
            echo "    No .json files found in $folder"
        fi
    done
done

echo "Processing complete!"