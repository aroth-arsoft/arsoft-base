#include <iostream>
#include <errno.h>
#include <boost/program_options.hpp>
#include <boost/filesystem.hpp>
#include "opts_helper.h"
#include "krb5_wrapper.h"

using namespace std;
using namespace arsoft::krb5;

#define SYSTEM_KEYTAB "/etc/krb5.keytab"

struct console_list_handler {
    enum OutputLevel {
        OutputLevelPrincipal = 0x01,
        OutputLevelKeyVersion = 0x02,
        OutputLevelEncryptionType = 0x04,
        OutputLevelTimestamp = 0x08,
        OutputLevelMagic = 0x10,
        OutputLevelDefault = OutputLevelPrincipal|OutputLevelKeyVersion|OutputLevelEncryptionType|OutputLevelTimestamp
    };
    OutputLevel _level;
    console_list_handler(OutputLevel level=OutputLevelDefault)
        : _level(level) {}

    void operator()(const keytab_entry & e)
    {
        bool first = true;
        if(_level & OutputLevelMagic)
        {
            if(!first) cout << ", ";
            first = false;
            cout << std::hex << e.get_magic() << std::dec;
        }
        if(_level & OutputLevelPrincipal)
        {
            if(!first) cout << ", ";
            first = false;
            cout << e.get_principal().name();
        }
        if(_level & OutputLevelKeyVersion)
        {
            if(!first) cout << ", ";
            first = false;
            cout << e.get_key_version();
        }
        if(_level & OutputLevelKeyVersion)
        {
            if(!first) cout << ", ";
            first = false;
            cout << e.get_encryption_as_string();
        }
        if(_level & OutputLevelKeyVersion)
        {
            if(!first) cout << ", ";
            first = false;
            cout << e.get_timestamp().to_string();
        }
        if(!first)
            cout << endl;
    }
};

struct sorted_list_handler {
    typedef std::list<keytab_entry> keytab_entry_list;
    keytab_entry_list _list;
    sorted_list_handler()
    {
    }

    void operator()(const keytab_entry & e)
    {
        _list.push_back(e);
    }

    static bool sort_by_principal(const keytab_entry& first, const keytab_entry& second)
    {
        return first.get_principal() < second.get_principal();
    }

    template<typename LIST_HANDLER>
    void list(LIST_HANDLER & handler)
    {
        _list.sort(sort_by_principal);
        for(keytab_entry_list::const_iterator it = _list.begin(); it != _list.end(); ++it)
        {
            const keytab_entry & entry = *it;
            handler(entry);
        }
    }

};



int main(int argc, char ** argv)
{
    int ret = 0;

    std::string appName = boost::filesystem::basename(argv[0]);
    std::string command;

    namespace po = boost::program_options;
    po::options_description desc("Options");
    desc.add_options()
      ("help,h", "Print help messages")
      ("verbose,v", "enable verbose output")
      ("version,V", "show version number")
      ("list,l", po::value<vector<string> >()->multitoken()->zero_tokens()->composing(), "list all entries of the given keytab")
      ("update,u", po::value< vector<string> >()->multitoken()->zero_tokens()->composing(), "copies new or missing entries from source keytab to destination")
      ("copy,c", po::value< vector<string> >()->multitoken()->zero_tokens()->composing(), "copies all entries from source keytab to destination")
      ("expunge,E", po::value< vector<string> >()->multitoken()->zero_tokens()->composing(), "remove all duplicated or obsolete keytab entries.")
      ("remove,r", po::value< vector<string> >()->multitoken()->zero_tokens()->composing(), "remove all entries with matching principals from the keytab")
      ;

    po::positional_options_description positionalOptions;

    po::variables_map vm;
    try
    {
        po::store(po::command_line_parser(argc, argv).options(desc).positional(positionalOptions).run(), vm); // throws on error
        /** --help option
        */
        if ( vm.count("help")  )
        {
            arsoft::OptionPrinter::printStandardAppDesc(appName,
                                                 std::cout,
                                                 desc,
                                                 &positionalOptions);
            return 0;
        }

        po::notify(vm); // throws on error, so do after help in case
                        // there are any problems
    }
    catch(boost::program_options::required_option& e)
    {
      arsoft::OptionPrinter::formatRequiredOptionError(e);
      std::cerr << "ERROR: " << e.what() << std::endl << std::endl;
      arsoft::OptionPrinter::printStandardAppDesc(appName,
                                               std::cout,
                                               desc,
                                               &positionalOptions);
      return 1;
    }
    catch(boost::program_options::error& e)
    {
      std::cerr << "ERROR: " << e.what() << std::endl << std::endl;
      arsoft::OptionPrinter::printStandardAppDesc(appName,
                                               std::cout,
                                               desc,
                                               &positionalOptions);
      return 1;
    }

    try {
        bool expunge = vm.count("expunge") != 0;
        vector<string> expunge_filenames;
        cout << "expunge: " << expunge << endl;

        context ctx;
        if( vm.count("version"))
        {
            cout << appName << " version " << TARGET_VERSION << " (" << TARGET_DISTRIBUTION << ")" << endl;
        }
        else if ( vm.count("list") )
        {
            vector<string> filenames = vm["list"].as< vector<string> >();
            if(filenames.empty())
                filenames.push_back(SYSTEM_KEYTAB);

            for(vector<string>::const_iterator it = filenames.begin(); it != filenames.end(); ++it)
            {
                const string & filename = *it;
                keytab kt(ctx, filename);
                cout << "Keytab name: FILE:" << filename << endl;
                sorted_list_handler sorted_handler;
                kt.list<sorted_list_handler>(sorted_handler);
                console_list_handler handler;
                sorted_handler.list<console_list_handler>(handler);
                if(expunge)
                    expunge_filenames.push_back(filename);
            }
        }
        else if( vm.count("update"))
        {
            vector<string> filenames = vm["update"].as< vector<string> >();
            string source = (filenames.size() >= 1) ? filenames[0] : string();
            string dest = (filenames.size() >= 2) ? filenames[1] : string();

            if(source.empty())
            {
                cerr << "No source keytab file given." << endl;
                ret = 1;
            }
            else if(dest.empty())
            {
                cerr << "No destination keytab file given." << endl;
                ret = 1;
            }
            else if(source == dest)
            {
                cerr << "Source and destination keytab file (" << source << ") are identical." << endl;
                ret = 1;
            }
            else
            {
                keytab sourceKeyTab(ctx, source);
                keytab destKeyTab(ctx, dest);
                if(destKeyTab.update(sourceKeyTab))
                    ret = 0;
                else
                    ret = 2;
                if(expunge)
                    expunge_filenames.push_back(dest);
            }
        }
        else if( vm.count("copy"))
        {
            vector<string> filenames = vm["copy"].as< vector<string> >();
            string source = (filenames.size() >= 1) ? filenames[0] : string();
            string dest = (filenames.size() >= 2) ? filenames[1] : string();

            if(source.empty())
            {
                cerr << "No source keytab file given." << endl;
                ret = 1;
            }
            else if(dest.empty())
            {
                cerr << "No destination keytab file given." << endl;
                ret = 1;
            }
            else if(source == dest)
            {
                cerr << "Source and destination keytab file (" << source << ") are identical." << endl;
                ret = 1;
            }
            else
            {
                keytab sourceKeyTab(ctx, source);
                keytab destKeyTab(ctx, dest);
                if(destKeyTab.copy(sourceKeyTab))
                    ret = 0;
                else
                    ret = 2;
                if(expunge)
                    expunge_filenames.push_back(dest);
            }
        }
        else if( vm.count("expunge"))
        {
            vector<string> filenames = vm["expunge"].as< vector<string> >();
            for(vector<string>::const_iterator it = filenames.begin(); it != filenames.end(); ++it)
                expunge_filenames.push_back(*it);
        }
        else if( vm.count("remove"))
        {
            vector<string> filenames = vm["remove"].as< vector<string> >();
            if(filenames.empty())
            {
                cerr << "No keytab file given." << endl;
                ret = 1;
            }
            else
            {
                vector<string>::const_iterator it = filenames.begin();
                string keytabFilename = *it;
                ++it;
                keytab keytab(ctx, keytabFilename);

                ret = 0;
                for(; it != filenames.end(); ++it)
                {
                    if(!keytab.remove(*it))
                        ret = 2;
                }
            }
        }
        else
        {
            cerr << "No action specified." << endl;
            ret = 2;
        }
        if(!ret && expunge)
        {
            ret = 0;
            for(vector<string>::const_iterator it = expunge_filenames.begin(); it != expunge_filenames.end(); ++it)
            {
                keytab keytab(ctx, *it);
                cout << "expunge " << *it << endl;
                if(!keytab.expunge())
                    ret = 2;
            }
        }
    }
    catch(error & e)
    {
        cerr << "Kerberos error " << e.code() << ": " << e.what() << endl;
    }

    return ret;
}
