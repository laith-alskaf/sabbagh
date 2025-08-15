// Prisma has been removed in favor of direct pg usage.
// This file is kept for backward compatibility in case of stray imports.
// Throwing here helps detect unintended usage during runtime.
throw new Error('Prisma is not configured. Use pg repositories instead.');