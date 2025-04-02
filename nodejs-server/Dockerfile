# Use a minimal Node.js runtime as the base image
FROM node:18-alpine

# Set the working directory
WORKDIR /usr/src/app

# Copy the prebuilt file into the container
COPY bin.cjs .

# Expose the port your server listens on
EXPOSE 5000

# Set environment variables
# ENV SUPERVISOR=SUPERVISOR_API

# Run the prebuilt file
CMD ["node", "bin.cjs", "http_server"]