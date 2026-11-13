import { ApiProperty } from '@nestjs/swagger';

export class ApiErrorDetail {
  @ApiProperty() field!: string;
  @ApiProperty() code!: string;
  @ApiProperty() message!: string;
}

export class ApiErrorResponse {
  @ApiProperty() code!: string;
  @ApiProperty() message!: string;
  @ApiProperty({ format: 'uuid' }) requestId!: string;
  @ApiProperty({ type: [ApiErrorDetail] }) details!: ApiErrorDetail[];
}
