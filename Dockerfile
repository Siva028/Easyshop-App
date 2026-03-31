# ── Stage 1: Install dependencies ────────────────────────────────
FROM node:20-alpine AS deps

WORKDIR /app

# Copy package files first — Docker layer cache means
# yarn install only re-runs when these files change
COPY package.json yarn.lock ./

RUN yarn install --frozen-lockfile --network-timeout 100000

# ── Stage 2: Build the Next.js app ───────────────────────────────
FROM node:20-alpine AS builder

WORKDIR /app

# Copy installed node_modules from deps stage
COPY --from=deps /app/node_modules ./node_modules

# Copy all source files
COPY . .

# Disable Next.js telemetry during build
ENV NEXT_TELEMETRY_DISABLED=1

# next.config.js must have output: 'standalone' for this to work
# That setting makes Next.js produce a self-contained server.js
RUN yarn build

# ── Stage 3: Production runner ────────────────────────────────────
FROM node:20-alpine AS runner

WORKDIR /app

ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1
ENV PORT=3000
ENV HOSTNAME="0.0.0.0"

# Create non-root user — never run containers as root
RUN addgroup --system --gid 1001 nodejs &&     adduser  --system --uid 1001 nextjs

# Copy only what's needed to run the app
# standalone/ contains a minimal server.js + required node_modules
COPY --from=builder /app/public                               ./public
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static     ./.next/static

USER nextjs

EXPOSE 3000

# Health check — Kubernetes liveness probe will use this
HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3   CMD wget -qO- http://localhost:3000/api/health || exit 1

CMD ["node", "server.js"]