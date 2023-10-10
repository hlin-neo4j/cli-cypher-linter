// Cummins data model questions (ranked)
// 1. Give me all calibrations for the 'BGT' product where HP rated power is 500 and rated Torque is 1850 lb-ft (Pound Feet)
// JSON output
WITH 'BGT' as productId
MATCH (c:Calibration)
WHERE (:Product{name:productId})-->(:Build)<-[:BELONGS_TO]-(c:Calibration)
WITH distinct c, productId
WHERE (c)<-[:BELONGS_TO]-(:ParameterGroup)-[:HAS_VALUE_PARAMETER]->(:ValueParameter {name:'_Advertised_Engine_Power', value:'336'})
    AND (c)<-[:BELONGS_TO]-(:ParameterGroup)-[:HAS_VALUE_PARAMETER]->(:ValueParameter {name:'_Peak_Torque', value:'2237'})
WITH distinct c, productId
return {productId:'BGT', calibrationBuilds:collect(c.ecm_code)}

// WIP  alternate 2

// 1. What value is Low_Idle_Max_Engine_Speed set to for calibration HD10001.09?" 
MATCH (c:Calibration{ecm_code:'HD10001.09'})<-[:BELONGS_TO]-(:ParameterGroup)-[:HAS_VALUE_PARAMETER]->(vp:ValueParameter {name:'C_TIB_Low_Idle_Max_Engine_Speed'})
return vp.value


// 1. Get all calibrations for product BGT that also has this same value set for Low_Idle_Max_Engine_Speed
MATCH (c:Calibration)<-[:BELONGS_TO]-(:ParameterGroup)-[:HAS_VALUE_PARAMETER]->(vp:Parameter {name:'C_TIB_Low_Idle_Max_Engine_Speed',value:'900.0'})
WHERE (:Product{name:'BGT'})-->(:Build)<-[:BELONGS_TO]-(c)
return c.ecm_code

// 2. Metadata and Calibration Content

// * Service Model Name - synonym to Product Id and comes from Build Data
MATCH (vp:ValueParameter{name:'C_DL_OBD_Protocol'})
MATCH (p:Product)-->(:Build)<-[:BELONGS_TO]-(:Calibration)<-[:BELONGS_TO]-(:ParameterGroup)-[:HAS_VALUE_PARAMETER]->(vp)
return distinct p.name AS `Service Model Name`

// * WIP How often do we tune PARAMETER specifically for customers

// * What is PARAMETER tuned to in: all cals of a product ID
MATCH (p:Product{name:$product})
MATCH (p)-->(:Build)<-[:BELONGS_TO]-(c:Calibration)<-[:BELONGS_TO]-(:ParameterGroup)-[:HAS_VALUE_PARAMETER]->(vp:ValueParameter{name:$pname})
RETURN c.ecm_code, vp.value

// // * What are all of the cals for OEM X
// WITH 'OEM_Pressure_X' as oem
// MATCH (a:Axis {name:oem})<-[:HAS_AXIS]-(:Parameter)<--(:ParameterGroup)-[:BELONGS_TO]->(c:Calibration)
// return c.ecm_code

// * WIP What are they key options for a given ECM code

// # POV questions that the graph needs to answer for the data model version 8_17.json
// * I have this Calibration, give me this Parameter from it
MATCH (:Calibration{ecm_code:$cal})<-[:BELONGS_TO]-(:ParameterGroup)-->(p:Parameter{name:$pname})
return p

// * I have this product, for all the cals in the latest build, give me all calibrations where this parameter equals this value
MATCH (p:Product{name:$product})-[LATEST_BUILD]->(:Build)<-[:BELONGS_TO]-(c:Calibration)
WHERE (c)<-[:BELONGS_TO]-(:ParameterGroup)-[:HAS_VALUE_PARAMETER]->(:ValueParameter{value:$value})
return distinct c

// * I have this product, give me all calibrations where this parameter equals this value
MATCH (p:Product{name:$product})-->(:Build)<-[:BELONGS_TO]-(c:Calibration)
WHERE (c)<-[:BELONGS_TO]-(:ParameterGroup)-[:HAS_VALUE_PARAMETER]->(:ValueParameter{value:$value})
return distinct c

// * For this ECM Code(calibration), show me how this value has changed with each revision
MATCH (c:Calibration) where c.ecm_code starts with 'HD10001.'
MATCH (c)<-[:BELONGS_TO]-(:ParameterGroup)-->(p:Parameter{name:$pname})
RETURN c.ecm_code as calibration, p.name as parameter, p.value as value



/////////////////////////////////////////
// ARRAY PARAMETERS
/////////////////////////////////////////

// *** Get values for ArrayXYZParameter C_CBR_Post2_Qty_Chi4_Table for calibration HD10001.09
with 'HD10001.09' as ecm, 'C_CBR_Post2_Qty_Chi4_Table' as tbl
MATCH (c:Calibration{ecm_code:ecm})<-[:BELONGS_TO]-(:ParameterGroup)-[:HAS_ARRAY_XYZ_PARAMETER]->(xyz:ArrayXYZParameter)-[:HAS_AXIS]->(az:ZAxis {name:tbl})
WITH distinct xyz, az
match (xyz)-[:HAS_AXIS]->(ax:XAxis)
match (xyz)-[:HAS_AXIS]->(ay:YAxis)
return {table:az.name, y:ay.value, x:ax.value, z:az.value}

// ***Get all calibrations for product BGT that use this table C_AIC_ct_CylsPerCutoutTbl with given z values
with 'C_AIC_ct_CylsPerCutoutTbl' as tbl, "3,3,3,2,2,2,1,1,1" as z
MATCH (az:ZAxis {name:tbl, value:z})
MATCH (c:Calibration)<-[:BELONGS_TO]-(:ParameterGroup)-[:HAS_ARRAY_XYZ_PARAMETER]->(xyzparam:ArrayXYZParameter)-[:HAS_AXIS]->(az)
return c.ecm_code

// 1. Get all calibrations for product BGT that use this table C_AIC_ct_CylsPerCutoutTbl with given values
with 'C_AIC_ct_CylsPerCutoutTbl' as tbl, '120,200,201' as x, '500,800,3000' as y, "3,3,3,2,2,2,1,1,1" as z
MATCH (az:ZAxis {name:tbl, value:z})
MATCH (xyzparam:ArrayXYZParameter)-[:HAS_AXIS]->(az)
WITH xyzparam
WHERE (:XAxis {value:x})<-[:HAS_AXIS]-(xyzparam)-[:HAS_AXIS]->(:YAxis {value:y})
MATCH (c:Calibration)<-[:BELONGS_TO]-()-[:HAS_ARRAY_XYZ_PARAMETER]->(xyzparam)
return c.ecm_code

// ****What is ArrayParameter tuned to in all cals of product ID
WITH 'BGT' as product
MATCH (p:Product{name:product})
MATCH (p)-->(:Build)<-[:BELONGS_TO]-(c:Calibration),
    (c)<-[:BELONGS_TO]-(:ParameterGroup)-[:HAS_ARRAY_XYZ_PARAMETER]->(xyz:ArrayXYZParameter)-[:HAS_AXIS]->(a:ZAxis {name:$zname})
WITH c, xyz
MATCH (xyz)-[:HAS_AXIS]->(a:Axis)
RETURN c.ecm_code as ecm_code, a.label as axisType, a.value as value

// ** I have this calibration, give me this xyz table parameter from it
with 'HD10001.08' as cal, 'C_AIC_ct_CylsPerCutoutTbl' as ztable
MATCH (c:Calibration{ecm_code:cal})<-[:BELONGS_TO]-(:ParameterGroup)-[:HAS_ARRAY_XYZ_PARAMETER]->(p:ArrayXYZParameter)-[:HAS_AXIS]->(az:ZAxis {name:ztable})
WITH cal, p, az
MATCH (p)-[:HAS_AXIS]->(ax:XAxis)
MATCH (p)-[:HAS_AXIS]->(ay:YAxis)
return {ecm_code:cal, paramName:p.name, x:ax.value, y:ay.value, z:az.value} as result

// For calibration HD10001, show how ArrayXYZParameter C_AIC_ct_CylsPerCutoutTbl has changed with each revision
// JSON formatted output
with 'HD10001.' as cal, 'C_AIC_ct_CylsPerCutoutTbl' as tbl
MATCH (c:Calibration) where c.ecm_code STARTS WITH cal
MATCH (c)<-[:BELONGS_TO]-(:ParameterGroup)-[:HAS_ARRAY_XYZ_PARAMETER]->(xyz)-[:HAS_AXIS]->(az:ZAxis{name:tbl})
WITH c,xyz,az
MATCH (xyz)-[:HAS_AXIS]->(ax:XAxis)
MATCH (xyz)-[:HAS_AXIS]->(ay:YAxis)
return {
    ecm_code:c.ecm_code, paramName:xyz.name, x:ax.value, y:ay.value, z:az.value,
    xName:ax.name, yName:ay.name, zName:az.name
} as result