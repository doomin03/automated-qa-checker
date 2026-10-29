import Ajv from 'ajv';
import bundle from '../generated/engine-contract.json' with { type:'json' };
export const engineContract=bundle;
const ajv=new Ajv({allErrors:true,strict:false,ownProperties:true});
ajv.addSchema(bundle.schema);
export function validateContract(value,name) {
 const validate=ajv.getSchema(bundle.schema.$id+'#/definitions/'+name);
 if(!validate || !validate(value)) throw new Error('규격 오류: '+(validate?.errors || []).slice(0,3).map(e=>e.instancePath+' '+e.message).join('; '));
 return value;
}

