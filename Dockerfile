# Use Node 22 for Svelte compatibility
FROM node:22-alpine AS builder

# Install build dependencies for native modules
RUN apk add --no-cache \
    python3 \
    make \
    g++ \
    git

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies with legacy peer deps flag for better compatibility
RUN npm install --legacy-peer-deps

# Copy source code
COPY . .

# Build the application
RUN npm run build

# Production stage
FROM node:22-alpine AS runner

# Set working directory
WORKDIR /app

# Create a non-root user
RUN addgroup -g 1001 -S nodejs
RUN adduser -S svelte -u 1001

# Copy built application with correct ownership
COPY --from=builder --chown=svelte:nodejs /app/build build/
COPY --from=builder --chown=svelte:nodejs /app/node_modules node_modules/
COPY --from=builder --chown=svelte:nodejs /app/package.json .

# Switch to non-root user
USER svelte

# Expose port
EXPOSE 3000

# Set environment variables
ENV NODE_ENV=production
ENV PORT=3000

# Start the application
CMD ["node", "build"]
