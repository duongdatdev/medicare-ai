import { SetMetadata, createParamDecorator, ExecutionContext } from '@nestjs/common';

export const PUBLIC_ROUTE = 'public-route';
export const ROLES = 'roles';
export const Public = () => SetMetadata(PUBLIC_ROUTE, true);
export const Roles = (...roles: string[]) => SetMetadata(ROLES, roles);
export const CurrentUser = createParamDecorator((_data: unknown, context: ExecutionContext) =>
  context.switchToHttp().getRequest().user,
);
