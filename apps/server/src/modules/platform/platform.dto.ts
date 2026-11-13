import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Transform, Type } from 'class-transformer';
import { ArrayMaxSize, IsArray, IsBase64, IsIn, IsInt, IsString, Matches, Max, MaxLength, Min, MinLength, ValidateIf, ValidateNested } from 'class-validator';

export const idPattern = '^[A-Za-z0-9][A-Za-z0-9_.-]{0,127}$';
export const roles = ['viewer', 'qa_tester', 'qa_editor', 'qa_manager', 'system_admin'] as const;
export type Role = typeof roles[number];
export const projectActions = ['readPublished', 'pinVersions', 'publishRuns', 'requestExecutions', 'manageSchedules', 'updateWork', 'createDrafts', 'reviewPublish', 'viewAudit', 'listMembers'] as const;
export type ProjectAction = typeof projectActions[number];
export const projectActionRoles: Readonly<Record<ProjectAction, Role>> = {
  readPublished: 'viewer', pinVersions: 'qa_tester', publishRuns: 'qa_tester',
  requestExecutions: 'qa_tester', manageSchedules: 'qa_tester', updateWork: 'qa_tester',
  createDrafts: 'qa_editor', reviewPublish: 'qa_manager', viewAudit: 'qa_manager', listMembers: 'qa_manager',
};
const optional = (_: unknown, value: unknown) => value !== undefined;

export class PageQuery {
  @ApiPropertyOptional({ type: 'integer', minimum: 1, maximum: 100, default: 50 })
  @ValidateIf(optional) @Transform(({ value }) => typeof value === 'string' && /^\d+$/.test(value) ? Number(value) : value)
  @IsInt() @Min(1) @Max(100) limit?: number;
  @ApiPropertyOptional() @ValidateIf(optional) @IsString() @MaxLength(256) cursor?: string;
}
export class VersionQuery extends PageQuery {
  @ApiPropertyOptional() @ValidateIf(optional) @Matches(new RegExp(idPattern)) packageId?: string;
}
export class EventsQuery {
  @ApiPropertyOptional({ type: 'integer', minimum: 0, maximum: 9007199254740991, default: 0 })
  @ValidateIf(optional) @Transform(({ value }) => typeof value === 'string' && /^\d+$/.test(value) ? Number(value) : value)
  @IsInt() @Min(0) @Max(Number.MAX_SAFE_INTEGER) afterSequence?: number;
  @ApiPropertyOptional({ type: 'integer', minimum: 1, maximum: 100, default: 50 })
  @ValidateIf(optional) @Transform(({ value }) => typeof value === 'string' && /^\d+$/.test(value) ? Number(value) : value)
  @IsInt() @Min(1) @Max(100) limit?: number;
}
export class DependencyPin {
  @ApiProperty() @Matches(new RegExp(idPattern)) versionId!: string;
  @ApiProperty({ pattern: '^[a-f0-9]{64}$' }) @Matches(/^[a-f0-9]{64}$/) sha256!: string;
}
export class DraftInput {
  @ApiProperty() @Matches(new RegExp(idPattern)) packageId!: string;
  @ApiProperty() @IsString() @MinLength(1) @MaxLength(200) title!: string;
  @ApiProperty({ description: 'Opaque Engine Blueprint XML. Validation does not execute it.' }) @IsString() @MinLength(1) @MaxLength(1048576) xml!: string;
  @ApiProperty({ type: [DependencyPin], maxItems: 100 }) @IsArray() @ArrayMaxSize(100) @ValidateNested({ each: true }) @Type(() => DependencyPin) dependencies!: DependencyPin[];
}
export class PublishInput {
  @ApiProperty({ pattern: '^\\d+\\.\\d+\\.\\d+$' }) @Matches(/^\d+\.\d+\.\d+$/) @MaxLength(64) version!: string;
}
export class PinInput {
  @ApiProperty() @Matches(new RegExp(idPattern)) versionId!: string;
  @ApiProperty({ pattern: '^[a-f0-9]{64}$' }) @Matches(/^[a-f0-9]{64}$/) sha256!: string;
}
export class DiffQuery {
  @ApiProperty() @Matches(new RegExp(idPattern)) fromVersionId!: string;
  @ApiProperty() @Matches(new RegExp(idPattern)) toVersionId!: string;
}
export class RunInput {
  @ApiProperty({ description: 'Immutable executed plan.blueprint JSON; Engine CLI recomputes the snapshot and node set.' }) @IsString() @MaxLength(1048576) blueprintJson!: string;
  @ApiProperty() @Matches(new RegExp(idPattern)) engineRunId!: string;
  @ApiProperty({ type: 'integer', minimum: 1, maximum: 1000000 }) @IsInt() @Min(1) @Max(1000000) attempt!: number;
  @ApiProperty({ pattern: '^sha256:[a-f0-9]{64}$' }) @Matches(/^sha256:[a-f0-9]{64}$/) snapshotHash!: string;
  @ApiProperty() @IsString() @MaxLength(64) engineVersion!: string;
  @ApiProperty({ description: 'Actual Engine run.started JSON; identity and snapshot must match the fields above. Stored as sequence 1.' }) @IsString() @MaxLength(1048576) startedEventJson!: string;
  @ApiPropertyOptional() @ValidateIf(optional) @Matches(new RegExp(idPattern)) versionId?: string;
}
export class EventBatchInput {
  @ApiProperty({ type: [String], maxItems: 100, description: 'Opaque Engine event JSON strings. All-or-nothing validation/append.' })
  @IsArray() @ArrayMaxSize(100) @IsString({ each: true }) @MaxLength(1048576, { each: true }) eventsJson!: string[];
}
export class ResultInput {
  @ApiProperty({ description: 'Opaque Engine qa.result/v1 JSON, immutable after acceptance.' }) @IsString() @MaxLength(1048576) resultJson!: string;
}
export class ArtifactInput {
  @ApiProperty({ description: 'Server issued ID from run.artifacts; never a filesystem path.' }) @Matches(new RegExp(idPattern)) artifactId!: string;
  @ApiProperty() @Matches(/^[a-f0-9]{64}$/) sha256!: string;
  @ApiProperty({ enum: ['image/png', 'application/json'] }) @IsIn(['image/png', 'application/json']) mimeType!: string;
  @ApiProperty({ description: 'Base64 bytes, maximum decoded 10 MiB; total run maximum 64 MiB.' }) @IsBase64() @MaxLength(13981016) base64!: string;
}
export class ProjectResponse {
  @ApiProperty() id!: string;
  @ApiProperty() name!: string;
  @ApiProperty({ enum: roles }) role!: Role;
}
export class ProjectEngineContext {
  @ApiProperty() engineVersion!: string;
  @ApiProperty() contractVersion!: string;
  @ApiProperty({ pattern: '^[a-f0-9]{64}$' }) contractSha256!: string;
  @ApiProperty({ type: String, nullable: true, pattern: '^[a-f0-9]{64}$', description: 'Installation archive pin metadata only; not a fresh archive verification guarantee. Null when unavailable.' }) archiveSha256!: string | null;
}
export class ProjectContextResponse {
  @ApiProperty() projectId!: string;
  @ApiProperty({ enum: roles }) role!: Role;
  @ApiProperty({ type: [String], enum: projectActions, description: 'Role-level entry hints for these capabilities only. Mutations still enforce current membership, ownership, independent review, revision and runtime compatibility.' }) allowedActions!: ProjectAction[];
  @ApiProperty({ type: ProjectEngineContext }) engine!: ProjectEngineContext;
}
export class ProjectMemberResponse {
  @ApiProperty() userId!: string;
  @ApiProperty({ type: String, nullable: true, description: 'Null: the current identity store has no display name field.' }) displayName!: string | null;
  @ApiProperty({ enum: roles }) role!: Role;
}
export class ProjectMemberPage {
  @ApiProperty({ type: [ProjectMemberResponse] }) items!: ProjectMemberResponse[];
  @ApiProperty({ type: String, nullable: true }) nextCursor!: string | null;
}
export class IdentityResponse {
  @ApiProperty() userId!: string;
  @ApiProperty({ type: Boolean, description: 'True for the explicitly configured local/test identity mode.' }) localMode!: boolean;
  @ApiProperty({ type: [ProjectResponse] }) projects!: ProjectResponse[];
}
export class ProjectPage {
  @ApiProperty({ type: [ProjectResponse] }) items!: ProjectResponse[];
  @ApiProperty({ type: String, nullable: true }) nextCursor!: string | null;
}
export class DraftResponse {
  @ApiProperty() id!: string;
  @ApiProperty() projectId!: string;
  @ApiProperty() packageId!: string;
  @ApiProperty() title!: string;
  @ApiProperty() xml!: string;
  @ApiProperty() sha256!: string;
  @ApiProperty({ type: [DependencyPin] }) dependencies!: DependencyPin[];
  @ApiProperty() authorId!: string;
  @ApiProperty({ enum: ['draft', 'reviewed', 'published'] }) state!: string;
  @ApiProperty({ type: String, nullable: true }) reviewerId!: string | null;
  @ApiProperty({ format: 'date-time' }) createdAt!: string;
}
export class DraftPage {
  @ApiProperty({ type: [DraftResponse] }) items!: DraftResponse[];
  @ApiProperty({ type: String, nullable: true }) nextCursor!: string | null;
}
export class VersionResponse {
  @ApiProperty() id!: string;
  @ApiProperty() projectId!: string;
  @ApiProperty() packageId!: string;
  @ApiProperty() version!: string;
  @ApiProperty() title!: string;
  @ApiProperty() xml!: string;
  @ApiProperty() sha256!: string;
  @ApiProperty({ type: [DependencyPin] }) dependencies!: DependencyPin[];
  @ApiProperty() engineVersion!: string;
  @ApiProperty() blueprintSnapshotHash!: string;
  @ApiProperty() flowSnapshotHash!: string;
  @ApiProperty({ format: 'date-time' }) createdAt!: string;
}
export class VersionPage {
  @ApiProperty({ type: [VersionResponse] }) items!: VersionResponse[];
  @ApiProperty({ type: String, nullable: true }) nextCursor!: string | null;
}
export class PinResponse {
  @ApiProperty() packageId!: string;
  @ApiProperty() versionId!: string;
  @ApiProperty() sha256!: string;
}
export class PinPage {
  @ApiProperty({ type: [PinResponse] }) items!: PinResponse[];
  @ApiProperty({ type: String, nullable: true }) nextCursor!: string | null;
}
export class UpgradeDiffResponse {
  @ApiProperty({ type: VersionResponse }) from!: VersionResponse;
  @ApiProperty({ type: VersionResponse }) to!: VersionResponse;
  @ApiProperty() xmlChanged!: boolean;
  @ApiProperty() dependenciesChanged!: boolean;
}
export class ArtifactResponse {
  @ApiProperty() artifactId!: string;
  @ApiProperty({ description: 'Engine logical artifact name; not a server path.' }) name!: string;
  @ApiProperty() sha256!: string;
  @ApiProperty({ type: 'integer', minimum: 0, maximum: 10485760 }) size!: number;
  @ApiProperty() mimeType!: string;
  @ApiProperty() uploaded!: boolean;
}
export class ArtifactDownload extends ArtifactResponse {
  @ApiProperty() base64!: string;
}
export class RunResponse {
  @ApiProperty({ description: 'Immutable normalized Engine Blueprint JSON used for this run.' }) blueprintJson!: string;
  @ApiProperty() id!: string;
  @ApiProperty() projectId!: string;
  @ApiProperty() ownerId!: string;
  @ApiProperty() engineRunId!: string;
  @ApiProperty({ type: 'integer' }) attempt!: number;
  @ApiProperty() snapshotHash!: string;
  @ApiProperty() engineVersion!: string;
  @ApiProperty({ type: String, nullable: true }) versionId!: string | null;
  @ApiProperty({ type: 'integer' }) lastSequence!: number;
  @ApiProperty() terminal!: boolean;
  @ApiProperty({ type: String, nullable: true, description: 'Externally reported Engine outcome; never a server re-execution verdict.' }) reportedOutcome!: string | null;
  @ApiProperty({ enum: ['pending', 'missing', 'verified'] }) evidenceStatus!: string;
  @ApiProperty({ enum: ['todo', 'in_progress', 'done'] }) workStatus!: string;
  @ApiProperty({ type: String, nullable: true }) resultJson!: string | null;
  @ApiProperty({ type: [ArtifactResponse] }) artifacts!: ArtifactResponse[];
  @ApiProperty({ format: 'date-time' }) createdAt!: string;
}
export class RunPage {
  @ApiProperty({ type: [RunResponse] }) items!: RunResponse[];
  @ApiProperty({ type: String, nullable: true }) nextCursor!: string | null;
}
export class EventsResponse {
  @ApiProperty() runId!: string;
  @ApiProperty() engineRunId!: string;
  @ApiProperty({ type: 'integer' }) attempt!: number;
  @ApiProperty() snapshotHash!: string;
  @ApiProperty({ type: [String] }) eventsJson!: string[];
  @ApiProperty({ type: 'integer' }) nextSequence!: number;
  @ApiProperty() hasMore!: boolean;
  @ApiProperty() terminal!: boolean;
}
export class AuditResponse {
  @ApiProperty() id!: string;
  @ApiProperty() actorId!: string;
  @ApiProperty() action!: string;
  @ApiProperty() resourceId!: string;
  @ApiProperty({ format: 'date-time' }) createdAt!: string;
}
export class AuditPage {
  @ApiProperty({ type: [AuditResponse] }) items!: AuditResponse[];
  @ApiProperty({ type: String, nullable: true }) nextCursor!: string | null;
}
