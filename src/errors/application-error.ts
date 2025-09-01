export class ApplicationError extends Error {
    constructor(
        message: string,
        public readonly statusCode: number = 500
    ) {
        super(message);
        this.name = this.constructor.name;
        Error.captureStackTrace(this, this.constructor);
    }
}

export class NotFoundError extends ApplicationError {
    constructor(message: string = 'Resource not found') {
        super(message, 404);
    }
}

export class BadRequestError extends ApplicationError {
    constructor(message: string = 'Bad request') {
        super(message, 400);
    }
}

export class ConflictRequestError extends ApplicationError {
    constructor(message: string = 'Conflict request') {
        super(message, 409);
    }
}


export class UnauthorizedError extends ApplicationError {
    constructor(message: string = 'Unauthorized') {
        super(message, 401);
    }
}

export class ForbiddenError extends ApplicationError {
    constructor(message: string = 'Forbidden') {
        super(message, 403);
    }
}

export class ValidationError extends ApplicationError {
    constructor(message: string = 'Validation failed', public readonly errors?: string[]) {
        super(message, 422);
    }
}

export class InternalServerError extends ApplicationError {
    constructor(message: string = 'Internal server error') {
        super(message, 500);
    }
}

export class ServiceUnavailableError extends ApplicationError {
    constructor(message: string = 'Service unavailable') {
        super(message, 503);
    }
}

// Product-specific errors
export class ProductNotFoundError extends NotFoundError {
    constructor(productId?: string) {
        const message = productId 
            ? `Product with ID ${productId} not found`
            : 'Product not found';
        super(message);
    }
}

export class ProductAlreadyExistsError extends ConflictRequestError {
    constructor(productName?: string) {
        const message = productName 
            ? `Product with name "${productName}" already exists`
            : 'Product already exists';
        super(message);
    }
}

export class InsufficientStockError extends BadRequestError {
    constructor(productId?: string, requestedQuantity?: number, availableStock?: number) {
        let message = 'Insufficient stock';
        if (productId && requestedQuantity && availableStock !== undefined) {
            message = `Insufficient stock for product ${productId}. Requested: ${requestedQuantity}, Available: ${availableStock}`;
        }
        super(message);
    }
}

// Category-specific errors
export class CategoryNotFoundError extends NotFoundError {
    constructor(categoryId?: string) {
        const message = categoryId 
            ? `Category with ID ${categoryId} not found`
            : 'Category not found';
        super(message);
    }
}

// User-specific errors
export class UserNotFoundError extends NotFoundError {
    constructor(userId?: string) {
        const message = userId 
            ? `User with ID ${userId} not found`
            : 'User not found';
        super(message);
    }
}

export class InsufficientPermissionsError extends ForbiddenError {
    constructor(action?: string) {
        const message = action 
            ? `Insufficient permissions to perform action: ${action}`
            : 'Insufficient permissions';
        super(message);
    }
}