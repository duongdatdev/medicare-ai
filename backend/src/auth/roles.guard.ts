import { CanActivate, ExecutionContext, ForbiddenException, Injectable } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { ROLES } from './auth.decorators.js';

@Injectable()
export class RolesGuard implements CanActivate {
  constructor(private readonly reflector: Reflector) {}

  canActivate(context: ExecutionContext): boolean {
    const roles = this.reflector.getAllAndOverride<string[]>(ROLES, [
      context.getHandler(), context.getClass(),
    ]);
    if (!roles?.length) return true;
    if (roles.includes(context.switchToHttp().getRequest().user?.role)) return true;
    throw new ForbiddenException();
  }
}
