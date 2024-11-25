# Translate top-level index.md to German
lang="de"

# Add the configuration language
echo "lang: $lang" >> config.yaml

# translate the index
translate_md --input-markdown-filestring 'index.md' --output-subdir --target-lang ${lang} --authentication-key $DEEPL_AUTH_KEY

# Create an 'en' directory for top-level index.md if it doesn't exist
mkdir -p en
cp index.md en
cp ${lang}/index.md .

# Define an array of directories to process
directories=("episodes" "instructors" "profiles" "learners")

# Loop through each directory in the array
for dir in "${directories[@]}"; do
    # Translate markdown files to Spanish
    translate_md --input-markdown-filestring "${dir}/*.md" --output-subdir --target-lang ${lang} --authentication-key $DEEPL_AUTH_KEY
    # Move into the directory
    cd "$dir"
    # Create an 'en' subdirectory if it doesn't exist, and copy original files into it
    mkdir -p en
    cp *.md en
    # Copy translated files (in 'es' subdirectory) to the current directory
    cp ${lang}/*.md .
    # Move back to the root directory
    cd ..
done

