
// Export our function
module.exports = async function (context, req) {
    // setup our default content type (we always return JSON)
    context.res = {
        header: {
            "Content-Type": "application/json"
        }
    }

    // Grab the id from the URL (stored in bindingData)
    const id = `EXPORT_${context.bindingData.id}`;

    context.res.body = { setting: id, value: process.env[id] };
};
