# Build ExtractIPA iOS App in Docker
# Allows building the iOS app on any system with Docker installed

FROM ghcr.io/actions/runner-images:macOS-latest

LABEL maintainer="Harsh Dhamaniya <https://github.com/harshdhamaniya>"
LABEL description="ExtractIPA iOS App Builder"

# Install dependencies
RUN brew install xcode-tools

# Set working directory
WORKDIR /app

# Copy project files
COPY . .

# Create build directory
RUN mkdir -p build

# Run build script
RUN chmod +x build.sh && ./build.sh

# Output
RUN ls -lh *.ipa

# Keep container running
CMD ["/bin/bash"]
