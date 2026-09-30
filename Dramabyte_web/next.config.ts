import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  distDir: process.env.DRAMABYTE_BUILD_DIR ?? ".next",
  images: {
    remotePatterns: [],
  },
};

export default nextConfig;
